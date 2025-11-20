// Import the audio streaming module
import {
  startAudioStream,
  stopAudioStream,
  addAudioSampleListener,
} from '@loqalabs/loqa-audio-bridge';
import { useState, useEffect } from 'react';
import { StyleSheet, Text, View, Button } from 'react-native';
import { Audio } from 'expo-av';

export default function App() {
  // Component state
  const [isStreaming, setIsStreaming] = useState(false);
  const [rmsLevel, setRmsLevel] = useState(0);
  const [permissionStatus, setPermissionStatus] = useState<'granted' | 'denied' | 'pending'>(
    'pending'
  );
  const [error, setError] = useState<string | null>(null);

  // Request microphone permission
  const requestPermissions = async () => {
    try {
      // Request microphone permission using expo-av
      const { status } = await Audio.requestPermissionsAsync();
      setPermissionStatus(status === 'granted' ? 'granted' : 'denied');
      return status === 'granted';
    } catch (err) {
      console.error('Permission request failed:', err);
      setError('Failed to request microphone permission');
      return false;
    }
  };

  // Request permission on mount
  useEffect(() => {
    requestPermissions();
  }, []);

  // Start audio streaming
  const handleStartStreaming = async () => {
    try {
      // Check permission first
      if (permissionStatus !== 'granted') {
        const granted = await requestPermissions();
        if (!granted) {
          setError('Microphone permission is required');
          return;
        }
      }

      // Configure audio stream: 16kHz sample rate, 2048 buffer size
      // This gives ~8 Hz event rate (2048 samples / 16000 Hz = 0.128s per event)
      await startAudioStream({
        sampleRate: 16000,
        bufferSize: 2048,
        channels: 1, // Mono
        vadEnabled: true, // Enable Voice Activity Detection for battery savings
      });

      setIsStreaming(true);
      setError(null);
    } catch (err) {
      console.error('Failed to start streaming:', err);
      setError('Failed to start audio streaming');
    }
  };

  // Stop audio streaming
  const handleStopStreaming = async () => {
    try {
      stopAudioStream();
      setIsStreaming(false);
    } catch (err) {
      console.error('Failed to stop streaming:', err);
      setError('Failed to stop audio streaming');
    }
  };

  // Listen for audio samples
  useEffect(() => {
    // Listen for audio samples
    const subscription = addAudioSampleListener((event) => {
      // event.samples: number[] of audio data
      // event.rms: root mean square (volume level)
      // event.sampleRate: configured sample rate
      setRmsLevel(event.rms);
    });

    // Cleanup: unsubscribe when component unmounts
    return () => {
      subscription.remove();
      if (isStreaming) {
        stopAudioStream().catch(console.error);
      }
    };
  }, []);

  return (
    <View style={styles.container}>
      {/* App Title */}
      <Text style={styles.title}>Loqa Audio Bridge Example</Text>

      {/* Permission Status */}
      <View style={styles.statusSection}>
        <Text style={styles.label}>Permission Status:</Text>
        <Text
          style={[styles.status, permissionStatus === 'granted' ? styles.granted : styles.denied]}
        >
          {permissionStatus === 'granted' ? '✓ Granted' : '✗ Not Granted'}
        </Text>
      </View>

      {/* Streaming Status */}
      <View style={styles.statusSection}>
        <Text style={styles.label}>Streaming:</Text>
        <Text style={[styles.status, isStreaming ? styles.active : styles.inactive]}>
          {isStreaming ? '● Active' : '○ Stopped'}
        </Text>
      </View>

      {/* Configuration Display */}
      <View style={styles.configSection}>
        <Text style={styles.configLabel}>Configuration:</Text>
        <Text style={styles.configText}>• Sample Rate: 16000 Hz</Text>
        <Text style={styles.configText}>• Buffer Size: 2048 samples</Text>
        <Text style={styles.configText}>• Channels: 1 (Mono)</Text>
        <Text style={styles.configText}>• VAD: Enabled</Text>
      </View>

      {/* RMS Visualization */}
      <View style={styles.visualizationSection}>
        <Text style={styles.label}>Volume Level (RMS):</Text>
        <Text style={styles.rmsValue}>{rmsLevel.toFixed(4)}</Text>
        <View style={styles.barContainer}>
          <View style={[styles.bar, { width: `${Math.min(rmsLevel * 100, 100)}%` }]} />
        </View>
      </View>

      {/* Control Buttons */}
      <View style={styles.buttonsContainer}>
        <Button
          title="Start Streaming"
          onPress={handleStartStreaming}
          disabled={isStreaming}
          color="#4CAF50"
        />
        <View style={styles.buttonSpacer} />
        <Button
          title="Stop Streaming"
          onPress={handleStopStreaming}
          disabled={!isStreaming}
          color="#F44336"
        />
      </View>

      {/* Error Display */}
      {error && (
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 30,
    textAlign: 'center',
  },
  statusSection: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 8,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    marginRight: 8,
  },
  status: {
    fontSize: 16,
  },
  granted: {
    color: '#4CAF50',
  },
  denied: {
    color: '#F44336',
  },
  active: {
    color: '#4CAF50',
  },
  inactive: {
    color: '#999',
  },
  configSection: {
    marginVertical: 20,
    padding: 15,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    width: '100%',
  },
  configLabel: {
    fontSize: 16,
    fontWeight: '600',
    marginBottom: 8,
  },
  configText: {
    fontSize: 14,
    color: '#666',
    marginVertical: 2,
  },
  visualizationSection: {
    width: '100%',
    marginVertical: 20,
  },
  rmsValue: {
    fontSize: 32,
    fontWeight: 'bold',
    textAlign: 'center',
    marginVertical: 10,
  },
  barContainer: {
    width: '100%',
    height: 30,
    backgroundColor: '#e0e0e0',
    borderRadius: 15,
    overflow: 'hidden',
  },
  bar: {
    height: '100%',
    backgroundColor: '#4CAF50',
  },
  buttonsContainer: {
    flexDirection: 'row',
    marginTop: 30,
  },
  buttonSpacer: {
    width: 20,
  },
  errorContainer: {
    marginTop: 20,
    padding: 10,
    backgroundColor: '#ffebee',
    borderRadius: 4,
    width: '100%',
  },
  errorText: {
    color: '#c62828',
    textAlign: 'center',
  },
});
