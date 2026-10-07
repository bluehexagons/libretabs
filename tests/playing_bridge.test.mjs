// SPDX-License-Identifier: Apache-2.0
import {test} from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
const code = readFileSync(new URL('../src/platform/playing_bridge.js', import.meta.url), 'utf8');
function host(navigator={}) {
  const sandbox={window:{}, navigator, performance:{now:()=>100}, console};
  vm.runInNewContext(code,sandbox);
  return sandbox.window.libretabsInput;
}
test('unsupported and denied MIDI recover to off',async()=>{
  const unsupported=host();await unsupported.midiStart();
  assert.equal(JSON.parse(unsupported.midiStatus()).status,'INPUT_MIDI_UNSUPPORTED');
  const denied=host({requestMIDIAccess:async()=>{throw {name:'NotAllowedError'};}});
  await denied.midiStart();assert.equal(JSON.parse(denied.midiStatus()).status,'INPUT_MIDI_DENIED');
  denied.midiStop();assert.equal(JSON.parse(denied.midiStatus()).status,'INPUT_MIDI_OFF');
});
test('MIDI requests no sysex; queued events retain channel, velocity and age',async()=>{
  const port={id:'one',name:'Keyboard',state:'connected',close:async()=>{}};
  let options;
  const api=host({requestMIDIAccess:async(o)=>{options=o;return {inputs:new Map([['one',port]])};}});
  await api.midiStart();assert.equal(options.sysex,false);
  port.onmidimessage({data:[0x92,60,90],timeStamp:80});
  const events=JSON.parse(api.midiPull());assert.equal(events[0].channel,2);assert.equal(events[0].b,90);assert.equal(events[0].age,20);
  assert.deepEqual(JSON.parse(api.midiPull()),[]);
  api.midiStop();assert.equal(port.onmidimessage,null);
});
test('overflow releases state instead of dropping only a note-off',async()=>{
  const port={id:'one',state:'connected',close:async()=>{}};
  const api=host({requestMIDIAccess:async()=>({inputs:new Map([['one',port]])})});await api.midiStart();
  for(let i=0;i<300;i++)port.onmidimessage({data:[0x90,60,100],timeStamp:80});
  assert.deepEqual(JSON.parse(api.midiPull()),[{reset:true}]);
  assert.deepEqual(JSON.parse(api.midiPull()),[]);
});
test('late permission result after disconnect does not reactivate MIDI',async()=>{
  let resolve;
  const api=host({requestMIDIAccess:()=>new Promise(r=>resolve=r)});
  const pending=api.midiStart();api.midiStop();resolve({inputs:new Map()});await pending;
  assert.equal(JSON.parse(api.midiStatus()).status,'INPUT_MIDI_OFF');
});
test('device changes update the list and invalidate queued note state',async()=>{
  const port={id:'one',state:'connected',close:async()=>{}};
  const access={inputs:new Map([['one',port]])};
  const api=host({requestMIDIAccess:async()=>access});await api.midiStart();
  const revision=JSON.parse(api.midiStatus()).revision;
  port.onmidimessage({data:[0x90,60,100],timeStamp:80});port.state='disconnected';access.onstatechange();
  const report=JSON.parse(api.midiStatus());assert.ok(report.revision>revision);assert.equal(report.devices.length,0);
  assert.deepEqual(JSON.parse(api.midiPull()),[]);
});
test('only selectable MIDI ports receive handlers; reconnect respects the device cap',async()=>{
  const ports=Array.from({length:34},(_,i)=>({id:String(i),state:'connected',close:async()=>{}}));
  const access={inputs:new Map(ports.map(p=>[p.id,p]))};
  const api=host({requestMIDIAccess:async()=>access});await api.midiStart();
  assert.equal(JSON.parse(api.midiStatus()).devices.length,32);
  assert.equal(ports.filter(p=>typeof p.onmidimessage==='function').length,32);
  assert.equal(ports[32].onmidimessage,null);assert.equal(ports[33].onmidimessage,null);
  ports[0].state='disconnected';access.onstatechange();
  assert.equal(ports[0].onmidimessage,null);assert.equal(typeof ports[32].onmidimessage,'function');
  const hiddenCallback=ports[32].onmidimessage;
  ports[32].onmidimessage({data:[0x90,60,100],timeStamp:80});
  assert.equal(JSON.parse(api.midiPull())[0].device,'32');
  ports[0].state='connected';access.onstatechange();
  assert.equal(typeof ports[0].onmidimessage,'function');assert.equal(ports[32].onmidimessage,null);
  hiddenCallback({data:[0x90,64,100],timeStamp:80});assert.deepEqual(JSON.parse(api.midiPull()),[]);
  api.midiStop();assert.ok(ports.every(p=>p.onmidimessage===null));
});
test('saved MIDI callbacks cannot enqueue notes after disconnection or a new session',async()=>{
  const port={id:'one',state:'connected',close:async()=>{}};
  const access={inputs:new Map([['one',port]])};
  const api=host({requestMIDIAccess:async()=>access});await api.midiStart();
  const callback=port.onmidimessage;
  port.state='disconnected';access.onstatechange();
  callback({data:[0x90,60,100],timeStamp:80});assert.deepEqual(JSON.parse(api.midiPull()),[]);
  port.state='connected';access.onstatechange();
  api.midiStop();await api.midiStart();
  callback({data:[0x90,60,100],timeStamp:80});assert.deepEqual(JSON.parse(api.midiPull()),[]);
  port.onmidimessage({data:[0x90,64,100],timeStamp:80});
  assert.equal(JSON.parse(api.midiPull())[0].a,64);
});
function microphoneHost(getUserMedia, sampleRate=48000) {
  let node, stopped=0, closed=0;
  const track={stop(){stopped++;}};
  const stream={getTracks:()=>[track]};
  class Context {
    sampleRate=sampleRate;currentTime=2;destination={};
    audioWorklet={addModule:async()=>{}};
    resume=async()=>{};close=async()=>{closed++;};
    createMediaStreamSource(){return {connect(){},disconnect(){}};}
  }
  class Worklet {
    constructor(){node=this;this.port={close(){}};}
    connect(){} disconnect(){}
  }
  const sandbox={window:{AudioContext:Context,AudioWorkletNode:Worklet},navigator:{mediaDevices:{getUserMedia:getUserMedia|| (async()=>stream),enumerateDevices:async()=>[{kind:'audioinput',deviceId:'mic',label:'Microphone'}]}},performance:{now:()=>100},Blob,URL,console};
  vm.runInNewContext(code,sandbox);
  return {api:sandbox.window.libretabsInput,get node(){return node;},get stopped(){return stopped;},get closed(){return closed;},stream};
}
test('microphone unavailable and permission denial are explicit states',async()=>{
  const unsupported=host();await unsupported.micStart('');assert.equal(JSON.parse(unsupported.micStatus()).status,'INPUT_MIC_UNSUPPORTED');
  const denied=microphoneHost(async()=>{throw {name:'NotAllowedError'};});await denied.api.micStart('');
  assert.equal(JSON.parse(denied.api.micStatus()).status,'INPUT_MIC_DENIED');assert.equal(denied.closed,1);
});
test('microphone capture is bounded, discards stale data and releases hardware',async()=>{
  const env=microphoneHost();await env.api.micStart('');
  assert.equal(JSON.parse(env.api.micStatus()).status,'INPUT_MIC_READY');
  for(let i=0;i<25;i++)env.node.port.onmessage({data:{samples:new Float32Array(1024).fill(i).buffer,at:1.98}});
  assert.equal(JSON.parse(env.api.micStatus()).dropped,15);
  const batch=env.api.micPull();assert.equal(batch.samples.byteLength,32768);
  assert.equal(new Float32Array(batch.samples)[0],15); // Oldest retained block, in order.
  assert.equal(new Float32Array(batch.samples)[7*1024],22);
  assert.equal(env.api.micPull().samples.byteLength,8192);
  assert.equal(env.api.micPull(),null);
  env.node.port.onmessage({data:{samples:new Float32Array(1024).buffer,at:1}});
  assert.equal(env.api.micPull(),null);
  env.api.micStop();assert.equal(env.stopped,1);assert.equal(env.closed,1);
  assert.equal(JSON.parse(env.api.micStatus()).status,'INPUT_MIC_OFF');
});
test('high sample-rate capture retains a full detection window within the memory cap',async()=>{
  const env=microphoneHost(undefined,192000);await env.api.micStart('');
  for(let i=0;i<40;i++)env.node.port.onmessage({data:{samples:new Float32Array(1024).buffer,at:1.98}});
  assert.equal(JSON.parse(env.api.micStatus()).dropped,8);
  for(let i=0;i<4;i++)assert.equal(env.api.micPull().samples.byteLength,32768);
  assert.equal(env.api.micPull(),null);
  env.api.micStop();
});
test('canceling pending microphone permission stops the late stream',async()=>{
  let resolve, requested;
  const started=new Promise(r=>requested=r);
  const env=microphoneHost(()=>new Promise(r=>{resolve=r;requested();}));
  const pending=env.api.micStart('');await started;
  env.api.micStop();resolve(env.stream);await pending;
  assert.equal(env.stopped,1);assert.equal(JSON.parse(env.api.micStatus()).status,'INPUT_MIC_OFF');
});
