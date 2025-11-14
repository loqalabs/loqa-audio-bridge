import * as React from 'react';

import { LoqaAudioBridgeModuleViewProps } from './LoqaAudioBridgeModule.types';

export default function LoqaAudioBridgeModuleView(props: LoqaAudioBridgeModuleViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
