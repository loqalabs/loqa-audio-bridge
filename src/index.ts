// Reexport the native module. On web, it will be resolved to LoqaAudioBridgeModule.web.ts
// and on native platforms to LoqaAudioBridgeModule.ts
export { default } from './LoqaAudioBridgeModule';
export { default as LoqaAudioBridgeModuleView } from './LoqaAudioBridgeModuleView';
export * from './LoqaAudioBridgeModule.types';
