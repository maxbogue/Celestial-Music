import Graphics.UI.GLUT hiding (Sphere)
import Data.IORef

import Display
import Input (readSpheres)
import Sphere

reduceSphere s = Sphere {
    distance = (distance s) ** (1/4) * windowScale / 300,
    period   = period s,
    mass     = mass s}

main = do 
    spheres <- readSpheres
    spheresRef <- newIORef $ map reduceSphere spheres
    anglesRef <- let n = fromIntegral $ length spheres in
        newIORef [0 | i <- [1..n]]

    getArgsAndInitialize
    createWindow "Celestial Music"
    (let n = fromInteger windowPixels in windowSize $= Size n n)
    pointSmooth $= Enabled
    blend $= Enabled
    blendFunc $= (SrcAlpha, OneMinusSrcAlpha)
    displayCallback $= display spheresRef anglesRef
    idleCallback $= Just (idle spheresRef anglesRef)
    reshapeCallback $= Just reshape

    mainLoop
