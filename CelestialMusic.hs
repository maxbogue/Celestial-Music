{-import Graphics.Rendering.OpenGL-}
import Graphics.UI.GLUT
import Data.IORef

import Display
import Input (readSpheres)

main = do 
    spheres <- readSpheres
    putStrLn $ show spheres
    (progname, _) <- getArgsAndInitialize
    createWindow "Celestial Music"
    pointSmooth $= Enabled
    blend $= Enabled
    blendFunc $= (SrcAlpha, OneMinusSrcAlpha)
    displayCallback $= display
    reshapeCallback $= Just reshape
    mainLoop
