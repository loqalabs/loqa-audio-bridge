import { NativeModule, requireNativeModule } from 'expo';

import { LoqaAudioBridgeModuleEvents } from './LoqaAudioBridgeModule.types';

declare class LoqaAudioBridgeModule extends NativeModule<LoqaAudioBridgeModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<LoqaAudioBridgeModule>('LoqaAudioBridgeModule');
