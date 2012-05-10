module Display where

import Graphics.UI.GLUT

renderCircle :: (Float, Float) -> Float -> IO ()
renderCircle (x, y) r = do
    pointSize $= 50 * r
    renderPrimitive Points $ vertex (Vertex2 x y)
    pointSize $= 1

reshape s = do
    viewport $= (Position 0 0, s)
    postRedisplay Nothing

display = do 
    clear [ColorBuffer]
    --renderPrimitive TriangleFan $ mapM_ (\(x, y) -> vertex $ Vertex2 x y) myPoints
    renderCircle (0, 0.5) 1
    renderCircle (0.5, 0) 1
    renderCircle (0, -0.5) 1
    renderCircle (-0.5, 0) 1
    flush
