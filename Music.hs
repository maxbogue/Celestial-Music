module Music (initOpenAL, playSine) where

import Control.Concurrent
import Sound.OpenAL
import Tomato

waveProduct :: [Integer -> Float] -> [Float]
waveProduct waveFuncs = map waveProduct' [0..] where
    waveProduct' t = foldl (*) 1 $ map (\f -> f t) waveFuncs

sampleRate :: SampleRate
sampleRate = 22050

dt :: Float
dt = 1 / sampleRate

sineWave :: Float -> Integer -> Float
sineWave freq t = sin $ 2 * pi * freq * dt * fromIntegral t

expDecay :: Float -> Integer -> Float
expDecay d t = 10 ** (-4 * dt / d * fromIntegral t)

playSine :: Float -> Float -> IO ThreadId
playSine d f = forkIO $
    withSpeakers sampleRate 128 $ \s -> playSamples s sound
  where
    sound = take (ceiling $ d / dt)
          $ waveProduct [expDecay d, sineWave f]
          -- $ map ((* 0.5) . sineWave f) [0..]

initOpenAL = do
    Just device  <- openDevice Nothing
    Just context <- createContext device []
    currentContext $= Just context

main = do
    initOpenAL
    playSine 1 440
    threadDelay 1000000
