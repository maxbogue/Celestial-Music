module Display where

import Graphics.UI.GLUT
import Sphere

windowPixels = 800 :: Integer
windowScale  = 100 :: Float
windowConversion = fromIntegral windowPixels / windowScale / 2

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
    mapM_ (\(s, a) -> renderCircle (distance s) a 2) (zip spheres angles)
    flush

idle spheresRef anglesRef = do
    angles <- get anglesRef
    anglesRef $=! (map (+ (pi / 5000)) angles)
    postRedisplay Nothing
