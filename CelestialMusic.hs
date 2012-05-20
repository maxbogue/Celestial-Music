import Data.Colour.RGBSpace
import Data.Colour.RGBSpace.HSV (hsv)
import Data.IORef
import Data.List (sort)
import Graphics.UI.GLUT hiding (RGB, Sphere)

import Display
import Input (readSpheres)
import Music
import Sphere

reduceSphere s = Sphere {
    distance = (distance s) ** (1/2) * windowScale / 8e4,
    period   = 0.5 / (period s ** (1/2)),
    mass     = 3.5e8 / (mass s ** (1/4))}

colorList :: Int -> [Color3 Float]
colorList n = [case hsv (fromIntegral i * 360 / fromIntegral n) 1 1 of
    RGB r g b -> Color3 r g b | i <- [0..n-1]]

main = do 
    spheres <- readSpheres
    spheresRef <- newIORef $ map reduceSphere (sort spheres)
    anglesRef <- let n = fromIntegral $ length spheres in
        newIORef [0 | i <- [1..n]]
    let colors = colorList $ length spheres

    initOpenAL

    getArgsAndInitialize
    initialDisplayMode $= [DoubleBuffered]
    createWindow "Celestial Music"
    (let n = fromInteger windowPixels in windowSize $= Size n n)
    pointSmooth $= Enabled
    blend $= Enabled
    blendFunc $= (SrcAlpha, OneMinusSrcAlpha)
    displayCallback $= display spheresRef anglesRef colors
    addTimerCallback 0 $ timer spheresRef anglesRef
    reshapeCallback $= Just reshape

    mainLoop
