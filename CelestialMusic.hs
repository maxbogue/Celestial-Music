import Graphics.UI.GLUT hiding (Sphere)
import Data.IORef

import Display
import Input (readSpheres)
import Sphere

reduceSphere s = Sphere {
    distance = (distance s) ** (1/2) * windowScale / 8e4,
    period   = 1 / (period s ** (1/2)),
    mass     = mass s}

main = do 
    spheres <- readSpheres
    spheresRef <- newIORef $ map reduceSphere spheres
    anglesRef <- let n = fromIntegral $ length spheres in
        newIORef [0 | i <- [1..n]]

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
