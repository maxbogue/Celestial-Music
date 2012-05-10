{-import Graphics.Rendering.OpenGL-}
import Graphics.UI.GLUT

blue :: Color3 Float
blue = Color3 0.0 0.0 1.0

renderFan points = do
    renderPrimitive TriangleFan $ mapM_ (\(x,y) -> vertex $ Vertex2 x y) points

renderCircle :: (Double, Double) -> Float -> IO ()
renderCircle (x, y) r = do
    pointSize $= 50 * r
    renderPrimitive Points $ vertex (Vertex2 x y)
    pointSize $= 1


main = do 
    (progname, _) <- getArgsAndInitialize
    createWindow "Hello World"
    displayCallback $= display
    reshapeCallback $= Just reshape
    pointSmooth $= Enabled
    blend $= Enabled
    blendFunc $= (SrcAlpha, OneMinusSrcAlpha)
    mainLoop

reshape s = do
    viewport $= (Position 0 0, s)
    postRedisplay Nothing

display = do 
    clear [ColorBuffer]
    --renderPrimitive TriangleFan $ mapM_ (\(x, y) -> vertex $ Vertex2 x y) myPoints
    renderCircle (0, 0.5) 1
    renderCircle (0.5, 0) 1
    color blue
    renderCircle (0, -0.5) 1
    renderCircle (-0.5, 0) 1
    flush
