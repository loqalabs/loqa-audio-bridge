import { registerWebModule, NativeModule } from 'expo';

import { LoqaAudioBridgeModuleEvents } from './LoqaAudioBridgeModule.types';

class LoqaAudioBridgeModule extends NativeModule<LoqaAudioBridgeModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(LoqaAudioBridgeModule, 'LoqaAudioBridgeModule');
