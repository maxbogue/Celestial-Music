import Data.IORef
import Data.List (sort)
import Graphics.UI.GLUT hiding (Sphere)

import Display
import Input (readSpheres)
import Music
import Sphere

reduceSphere s = Sphere {
    distance = (distance s) ** (1/2) * windowScale / 8e4,
    period   = 0.5 / (period s ** (1/2)),
    mass     = 3.5e8 / (mass s ** (1/4))}

main = do 
    spheres <- readSpheres
    spheresRef <- newIORef $ map reduceSphere (sort spheres)
    anglesRef <- let n = fromIntegral $ length spheres in
        newIORef [0 | i <- [1..n]]

    initOpenAL

    getArgsAndInitialize
    initialDisplayMode $= [DoubleBuffered]
    createWindow "Celestial Music"
    (let n = fromInteger windowPixels in windowSize $= Size n n)
    pointSmooth $= Enabled
    blend $= Enabled
    blendFunc $= (SrcAlpha, OneMinusSrcAlpha)
    displayCallback $= display spheresRef anglesRef
    addTimerCallback 0 $ timer spheresRef anglesRef
    reshapeCallback $= Just reshape

    mainLoop
