module Display where

import Graphics.UI.GLUT
import Sphere

windowPixels = 800 :: Integer
windowScale  = 100 :: Float
windowConversion = fromIntegral windowPixels / windowScale / 2

circleColors :: [Color3 Float]
circleColors = [
    Color3 ( 15 / 255) ( 80 / 255) (170 / 255),
    Color3 (190 / 255) (  0 / 255) (140 / 255),
    Color3 (  0 / 255) (180 / 255) (240 / 255),
    Color3 (255 / 255) (155 / 255) (  0 / 255)]

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
        (zip3 spheres angles [1..])
    swapBuffers

timer spheresRef anglesRef = do
    angles <- get anglesRef
    spheres <- get spheresRef
    anglesRef $=! (map (\(s, a) -> a + period s) (zip spheres angles))
    addTimerCallback 10 $ timer spheresRef anglesRef
    postRedisplay Nothing
