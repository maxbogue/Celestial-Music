module Display where

import Graphics.UI.GLUT
import Sphere
import Music

windowPixels = 800 :: Integer
windowScale  = 100 :: Float
windowConversion = fromIntegral windowPixels / windowScale / 2

circleColors :: [Color3 Float]
circleColors = [
    Color3 (255 / 255) (  0 / 255) (  0 / 255),
    Color3 (255 / 255) (153 / 255) (  0 / 255),
    Color3 (204 / 255) (255 / 255) (  0 / 255),
    Color3 ( 51 / 255) (255 / 255) (  0 / 255),
    Color3 (  0 / 255) (255 / 255) (102 / 255),
    Color3 (  0 / 255) (255 / 255) (255 / 255),
    Color3 (  0 / 255) (102 / 255) (255 / 255),
    Color3 ( 51 / 255) (  0 / 255) (255 / 255),
    Color3 (204 / 255) (  0 / 255) (255 / 255),
    Color3 (255 / 255) (  0 / 255) (153 / 255)]

renderCircle :: Float -> Float -> Float -> IO ()
renderCircle d a r = do
    pointSize $= (r * windowConversion)
    renderPrimitive Points $ vertex (Vertex2 (d * cos a) (d * sin a))
    pointSize $= 1

reshape s = do
    viewport $= (Position 0 0, s)
    postRedisplay Nothing

display spheresRef anglesRef = do
    clear [ColorBuffer]
    loadIdentity
    (let s = 1 / windowScale in scale s s s)
    spheres <- get spheresRef
    angles <- get anglesRef
    mapM_
        (\(s, a, i) -> preservingMatrix $ do
            color $ circleColors !! (i `mod` length circleColors)
            renderCircle (distance s) a 2)
        (zip3 spheres angles [0..])
    swapBuffers

timer spheresRef anglesRef = do
    angles <- get anglesRef
    spheres <- get spheresRef
    newAngles <- sequence $ zipWith
        (\s a -> do
            let a' = a + period s
            if a' > 2 * pi
                then do
                    playSine (0.01 * pi / period s) (50 + mass s)
                    {-playSine 1 (mass s)-}
                    return $ a' - 2 * pi
                else do
                    return a')
        spheres angles
    anglesRef $=! newAngles
    addTimerCallback 10 $ timer spheresRef anglesRef
    postRedisplay Nothing
