import { requireNativeView } from 'expo';
import * as React from 'react';

import { LoqaAudioBridgeModuleViewProps } from './LoqaAudioBridgeModule.types';

const NativeView: React.ComponentType<LoqaAudioBridgeModuleViewProps> =
  requireNativeView('LoqaAudioBridgeModule');

export default function LoqaAudioBridgeModuleView(props: LoqaAudioBridgeModuleViewProps) {
  return <NativeView {...props} />;
}
