#pragma once

#include <cstdint>

// Low-level PCM output interface.
// The audio engine (ported SPC-700 sequencer + DSP) produces interleaved
// stereo float samples and pushes them through this interface.
// Backends deliver the buffer to the OS audio API.
class IAudioOutput {
public:
    virtual ~IAudioOutput() = default;

    // sampleRate: e.g. 32000 (SNES native) or 44100/48000
    // channels:   1 (mono) or 2 (stereo)
    virtual bool init(int sampleRate, int channels) = 0;
    virtual void shutdown() = 0;

    // Push interleaved float samples in [-1.0, 1.0].
    // count is the total number of floats (frames * channels).
    // Non-blocking: returns immediately. The backend queues internally.
    virtual void submitSamples(const float* samples, int count) = 0;

    // How many frames are currently queued (for pacing).
    virtual int queuedFrames() const = 0;
};
