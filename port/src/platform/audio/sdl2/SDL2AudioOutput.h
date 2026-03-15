#pragma once
#ifdef FF5_AUDIO_SDL2

#include "platform/audio/IAudioOutput.h"
#include <SDL2/SDL.h>

class SDL2AudioOutput final : public IAudioOutput {
public:
    SDL2AudioOutput() = default;
    ~SDL2AudioOutput() override;

    bool init(int sampleRate, int channels) override;
    void shutdown() override;

    void submitSamples(const float* samples, int count) override;
    int  queuedFrames() const override;

private:
    SDL_AudioDeviceID m_device      = 0;
    int               m_channels    = 0;
    int               m_sampleRate  = 0;
};

#endif // FF5_AUDIO_SDL2
