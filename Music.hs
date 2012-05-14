import Sound.Tomato.Speakers

waveProduct :: [Integer -> Float] -> [Float]
waveProduct waveFuncs = map waveProduct' [0..] where
    waveProduct' t = foldl (*) 1 $ map (\f -> f t) waveFuncs

sampleRate = 22050

dt :: Float
dt         = 1 / sampleRate

sineWave freq t = sin $ 2 * pi * freq * dt * fromIntegral t

expDecay t = exp $ -3 * dt * fromIntegral t

playSine f = withSpeakers sampleRate 128 $ \s -> playSamples s sound
  where
    sound = take (ceiling $ 2 / dt)
          $ waveProduct [expDecay, sineWave f]
          -- $ map ((* 0.5) . sineWave f) [0..]

main = do
    playSine 440
