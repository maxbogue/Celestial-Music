{-

This is a slightly modified version of the tomato-rubato library:
http://hackage.haskell.org/package/tomato-rubato-openal

Copyright (c)2012, Heinrich Apfelmus

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of Heinrich Apfelmus nor the names of other
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-}
module Tomato (
    -- * Synopsis
    -- | Very small module for playing audio data on your speakers.
    -- 
    -- Currently based on the Haskell OpenAL bindings.
    
    -- * Setting up audio devices
    Speakers, SampleRate, standardSampleRates, BlockSize,
    withSpeakers, testSine,
    
    -- * Audio data and playback
    Sample, playSamples,
    AudioBlock, playBlock,
    ) where

import Control.Applicative
import Control.Monad

import Control.Exception
import Control.Concurrent
import Control.Concurrent.STM
import Data.Int (Int16)

import qualified Data.Vector.Storable as V

-- Code heavily adapated from from YampaSynth
-- which was written by George Giorgidze and Henrik Nilsson
import Sound.OpenAL

{-----------------------------------------------------------------------------
    Representation and playing of audio data
------------------------------------------------------------------------------}
-- | Single audio sample.
type Sample = Float

-- | Audio sample rate.
-- Needs to be one of the 'standardSampleRates' .
type SampleRate = Frequency

-- | List of standard sample rates, from high quality to low quality
-- 
-- > standardSampleRates = [44100,22050,11025]
standardSampleRates :: [SampleRate]
standardSampleRates = [44100,22050,11025]

-- | Size of an audio block.
--
-- The lower the block size, the lower the latency.
-- However, if the block size is too low, there will be jitter.
--
-- Recommended values: 64, 128, 256, 512
type BlockSize = Int

-- | Data type representing your loudspeakers.
data Speakers = Speakers
    { sampleRate  :: SampleRate
    , blockSize   :: BlockSize
    , source      :: Source
    , freeBuffers :: MyChan Buffer
    , usedBuffers :: MyChan Buffer
    }

-- | Initialize audio environment.
withSpeakers :: SampleRate -> BlockSize -> (Speakers -> IO a) -> IO a
withSpeakers rate size f = bracket init final try
    where
    init = do
        (source, buffers) <- initOpenAL 20
        s <- Speakers rate size source
            <$> newMyChan buffers <*> newMyChan []
        
        threadId <- forkIO $ recycleBuffers s   -- start buffer recycling
        return (s,source,buffers,threadId)

    final (s,source,buffers,threadId) = do
        killThread threadId                     -- stop buffer recycling
        deInitOpenAL (source,buffers)
    
    try (s,_,_,_) = do
        x <- f s
        waitForSource (source s)  -- wait for sound to finish playing
        return x

-- | Play a (possibly) infinite list of samples.
playSamples :: Speakers -> [Sample] -> IO ()
playSamples s = mapM_ (playBlock s) . map V.fromList . chunk (blockSize s)


-- | Memory block containing audio data.
-- Blockwise audio processing may be faster than lazy lists of samples.
type AudioBlock = V.Vector Sample

-- | Add a block of audio data to the speaker queue.
-- May block if the speaker has too much pending data.
playBlock :: Speakers -> AudioBlock -> IO ()
playBlock s block = do
    evaluate block
    (used, b) <- atomically $
        (,) <$> takeMyChan (usedBuffers s)
            <*> readMyChan (freeBuffers s)      -- get free buffer
    withBufferData s block (bufferData b $=)    -- write data
    queueBuffers (source s) [b]                 -- queue to source
    playing <- (== Playing) <$> get (sourceState $ source s)
    when (not playing) $ play [source s]        -- set status to Playing
    atomically $
        putMyChan (usedBuffers s) (used ++ [b]) -- mark buffer as used

{-----------------------------------------------------------------------------
    Test
------------------------------------------------------------------------------}
-- | Play a test sine wave.
-- Look at the source code to see how the library is used.
--
-- This should be a clear sound, similar to a telephone test tone.
-- If there is rattling or hissing, you have a problem.
--
-- > > testSine 440
testSine :: Frequency -> IO ()
testSine freq = withSpeakers sampleRate 128 $ \s -> playSamples s sound
    where
    sampleRate  = 22050
    dt          = 1 / sampleRate -- time in seconds of a single sample
    duration    = 3 -- seconds
    sound       = take (ceiling $ duration / dt)
                $ map (0.4*) $ sine freq
    
    sine freq = [sin (2*pi*freq*dt*fromIntegral t) | t <- [0..]]

    -- square freq = cycle $ replicate n 0 ++ replicate n 1
    --    where n = ceiling $ sampleRate / (2*freq)

{-----------------------------------------------------------------------------
    OpenAL glue code
------------------------------------------------------------------------------}
-- | Convert 'AudioBlock' to 'BufferData'
withBufferData :: Speakers -> AudioBlock -> (BufferData Int16 -> IO a) -> IO a
withBufferData speakers block f =
    V.unsafeWith blockInt16 $ \ptr -> do
        f $ BufferData (MemoryRegion ptr sizeInBytes)
                Mono16 (sampleRate speakers)
    where
    sizeInBytes = 2 * fromIntegral (V.length block)
    blockInt16  = V.map toSample block

-- | Convert a normalized floating point value in (-1,1) to a 'Sample'
toSample :: Float -> Int16
toSample = floor . (fromIntegral (maxBound - 1 :: Int16) *) . min 1 . max (-1)

-- | Process that recycles used buffers forever.
recycleBuffers :: Speakers -> IO ()
recycleBuffers s = forever $ do
    hasGarbage <- (> 0) <$> get (buffersProcessed $ source s)
    if not hasGarbage
        then threadDelay 10
        else do
            -- recycle the last used buffer
            buffer <- atomically $ readMyChan (usedBuffers s)
            unqueueBuffers (source s) [buffer]
            atomically $ writeMyChan (freeBuffers s) buffer

-- | Wait for an OpenAL source to complete playing.
waitForSource :: Source -> IO ()
waitForSource source = do
    isPlaying <- (== Playing) <$> (get $ sourceState source)
    when isPlaying $ do
        threadDelay 10
        waitForSource source

-- | Init OpenAL
initOpenAL :: Int -> IO (Source, [Buffer])
initOpenAL numBuffs = do
    [pSource] <- genObjectNames 1
    pBuffers  <- genObjectNames numBuffs
    printErrors
    return (pSource,pBuffers)

-- | Deinitialize OpenAL
deInitOpenAL :: (Source, [Buffer]) -> IO ()
deInitOpenAL (pSource,pBuffers) = do 
    buffer pSource $= Nothing
    deleteObjectNames [pSource]
    deleteObjectNames pBuffers
    printErrors

-- | Print all OpenAL errors if applicable
printErrors :: IO ()
printErrors = do
    e <- get alErrors
    when (not $ null e) $ print e

{-----------------------------------------------------------------------------
    Concurrency primitives
------------------------------------------------------------------------------}
type MyChan a = TMVar [a]

newMyChan :: [a] -> IO (MyChan a)
newMyChan = newTMVarIO

-- read single value from channel
readMyChan  :: MyChan a -> STM a
readMyChan c = do
    xs <- readTMVar c
    case xs of
        []     -> retry
        (x:xs) -> do
            takeTMVar c
            putTMVar c xs
            return x

-- write single value to channel
writeMyChan :: MyChan a -> a -> STM ()
writeMyChan c x = do
    xs <- takeTMVar c
    putTMVar c (xs ++ [x])

-- block channel
takeMyChan :: MyChan a -> STM [a]
takeMyChan = takeTMVar

-- unblock channel
putMyChan :: MyChan a -> [a] -> STM ()
putMyChan = putTMVar

{-----------------------------------------------------------------------------
    Utilities
------------------------------------------------------------------------------}
-- | Divide a list into chunks of n elements.
chunk :: Int -> [a] -> [[a]]
chunk n [] = []
chunk n xs = y : chunk n xs'
    where (y,xs') = splitAt n xs
