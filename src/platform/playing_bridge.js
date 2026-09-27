// SPDX-License-Identifier: Apache-2.0
// Session-only device input. No network, storage or MIDI output.
(() => {
  let midi, midiGeneration = 0, midiRevision = 0, midiQueue = [], overflow = false;
  let midiState = 'INPUT_MIDI_OFF';
  const midiPorts = () => midi ? [...midi.inputs.values()].filter(p => p.state === 'connected').slice(0, 32) : [];
  function attachMidi() {
    for (const port of midi.inputs.values()) {
      port.onmidimessage = port.state !== 'connected' ? null : event => {
        const d = event.data;
        if (!d || d.length !== 3 || ![8, 9, 11].includes(d[0] >> 4) || d[1] > 127 || d[2] > 127) return;
        if (midiQueue.length >= 256) { midiQueue = []; overflow = true; return; }
        if (!overflow) midiQueue.push({device:port.id, channel:d[0] & 15, message:d[0] >> 4, a:d[1], b:d[2], at: event.timeStamp});
      };
    }
    midiState = midiPorts().length ? 'INPUT_MIDI_READY' : 'INPUT_MIDI_EMPTY';
    midiRevision++;
  }
  let micGeneration = 0, micRevision = 0, micState = 'INPUT_MIC_OFF', micDevices = [];
  let micStream, micContext, micNode, micSource, micQueue = [], micDropped = 0;
  const processorCode = `
    class LibreTabsCapture extends AudioWorkletProcessor {
      constructor() { super(); this.block = new Float32Array(1024); this.used = 0; }
      process(inputs) {
        const channels = inputs[0];
        if (!channels || !channels.length) return true;
        for (let i=0; i<channels[0].length; i++) {
          let value=0;
          for (let c=0;c<channels.length;c++) value+=channels[c][i];
          this.block[this.used++]=value/channels.length;
          if(this.used===1024) {
            this.port.postMessage({samples:this.block.buffer,at:currentTime+(i+1)/sampleRate},[this.block.buffer]);
            this.block=new Float32Array(1024);this.used=0;
          }
        }
        return true;
      }
    }
    registerProcessor('libretabs-capture', LibreTabsCapture);
  `;
  function closeMic() {
    if(micNode) { micNode.port.onmessage=null; micNode.disconnect(); micNode.port.close(); }
    if(micSource) micSource.disconnect();
    if(micStream) for(const track of micStream.getTracks()) track.stop();
    if(micContext) Promise.resolve(micContext.close()).catch(()=>{});
    micStream=micContext=micNode=micSource=null;micQueue=[];
  }
  window.libretabsInput = {
    async micStart(device) {
      this.micStop();
      const generation=micGeneration;
      if(!navigator.mediaDevices?.getUserMedia || !window.AudioContext || !window.AudioWorkletNode) {
        micState='INPUT_MIC_UNSUPPORTED';micRevision++;return;
      }
      micState='INPUT_MIC_CONNECTING';micRevision++;
      try {
        // Resume in the initiating user gesture, before awaiting permission.
        const context=new window.AudioContext({latencyHint:'interactive'});
        micContext=context;
        await context.resume();
        if(generation!==micGeneration) return;
        const stream=await navigator.mediaDevices.getUserMedia({audio:{
          ...(device?{deviceId:{exact:device}}:{}),channelCount:{ideal:1},
          echoCancellation:false,noiseSuppression:false,autoGainControl:false
        },video:false});
        if(generation!==micGeneration) {stream.getTracks().forEach(t=>t.stop());return;}
        micStream=stream;
        const url=URL.createObjectURL(new Blob([processorCode],{type:'text/javascript'}));
        try {await context.audioWorklet.addModule(url);} finally {URL.revokeObjectURL(url);}
        if(generation!==micGeneration) return;
        const node=new window.AudioWorkletNode(context,'libretabs-capture',{numberOfInputs:1,numberOfOutputs:1,outputChannelCount:[1]});
        micNode=node;
        // Keep about 200 ms across sample rates, with a hard 128 KiB ceiling.
        const queueLimit=Math.min(32,Math.max(4,Math.ceil(context.sampleRate*0.2/1024)));
        node.port.onmessage=event=>{
          if(generation!==micGeneration)return;
          if(micQueue.length>=queueLimit){micQueue.shift();micDropped++;}
          micQueue.push({...event.data,rate:context.sampleRate});
        };
        micSource=context.createMediaStreamSource(stream);
        micSource.connect(node);node.connect(context.destination); // Processor writes silence to output.
        for(const track of stream.getTracks()) track.onended=()=>{
          if(generation!==micGeneration)return;
          this.micStop();micState='INPUT_MIC_ENDED';micRevision++;
        };
        micDevices=(await navigator.mediaDevices.enumerateDevices()).filter(d=>d.kind==='audioinput').slice(0,32).map(d=>({id:d.deviceId,name:String(d.label||'').slice(0,120)}));
        if(generation!==micGeneration)return;
        micState='INPUT_MIC_READY';micRevision++;
      } catch(error) {
        if(generation!==micGeneration)return;
        closeMic();
        micState=['NotAllowedError','SecurityError'].includes(error.name)?'INPUT_MIC_DENIED':error.name==='NotFoundError'?'INPUT_MIC_EMPTY':'INPUT_MIC_ERROR';
        micRevision++;
      }
    },
    micStop() { micGeneration++;closeMic();micState='INPUT_MIC_OFF';micRevision++;micDropped=0; },
    micStatus() { return JSON.stringify({status:micState,revision:micRevision,devices:micDevices,dropped:micDropped}); },
    micPull() {
      const block=micQueue.shift();if(!block)return null;
      const age=Math.max(0,(micContext.currentTime-block.at)*1000);
      if(age>250){micQueue=[];micDropped++;return null;}
      // Batch bridge crossings, while keeping each detector push <=8192 frames.
      const blocks=[block,...micQueue.splice(0,7)];
      const samples=new Float32Array(blocks.length*1024);
      blocks.forEach((item,index)=>samples.set(new Float32Array(item.samples),index*1024));
      const latest=blocks[blocks.length-1];
      return {samples:samples.buffer,rate:block.rate,age:Math.max(0,(micContext.currentTime-latest.at)*1000)};
    },
    async midiStart() {
      this.midiStop();
      const generation = midiGeneration;
      if (!navigator.requestMIDIAccess) { midiState = 'INPUT_MIDI_UNSUPPORTED'; midiRevision++; return; }
      midiState = 'INPUT_MIDI_CONNECTING'; midiRevision++;
      try {
        const access = await navigator.requestMIDIAccess({sysex:false});
        if (generation !== midiGeneration) return;
        midi = access;
        midi.onstatechange = () => { this.midiFlush(); attachMidi(); };
        attachMidi();
      } catch (error) {
        if (generation !== midiGeneration) return;
        midiState = error.name === 'NotAllowedError' || error.name === 'SecurityError' ? 'INPUT_MIDI_DENIED' : 'INPUT_MIDI_ERROR';
        midiRevision++;
      }
    },
    midiStop() {
      midiGeneration++;
      if (midi) {
        midi.onstatechange = null;
        for (const p of midi.inputs.values()) { p.onmidimessage = null; Promise.resolve(p.close()).catch(() => {}); }
      }
      midi = null; this.midiFlush(); midiState = 'INPUT_MIDI_OFF'; midiRevision++;
    },
    midiFlush() { midiQueue = []; overflow = false; },
    midiStatus() { return JSON.stringify({status:midiState, revision:midiRevision, devices:midiPorts().map(p => ({id:p.id, name:String(p.name || '').slice(0, 120)}))}); },
    midiPull() {
      if (overflow) { this.midiFlush(); return '[{"reset":true}]'; }
      const now = performance.now();
      const result = midiQueue.map(e => ({...e, age:Math.max(0, Math.min(2000, now - e.at || 0))}));
      midiQueue = [];
      return JSON.stringify(result);
    }
  };
  const suspend=()=>{window.libretabsInput.micStop();window.libretabsInput.midiFlush();};
  window.addEventListener?.('pagehide',suspend);
  if(typeof document!=='undefined')document.addEventListener('visibilitychange',()=>{if(document.hidden)suspend();});
})();
