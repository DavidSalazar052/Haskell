data Figura = Circulo Double | Rectangulo Double Double

area :: Figura -> Double
area (Circulo r)      = pi * r * r
area (Rectangulo b h) = b * h

clasificarArea :: Double -> String
clasificarArea a
  | a < 10    = "pequeña"
  | a < 100   = "mediana"
  | otherwise = "grande"

main :: IO ()
main = do
  let c = Circulo 5.0
  let r = Rectangulo 4.0 6.0
  putStrLn ("Área del círculo: " ++ show (area c) ++ " -> " ++ clasificarArea (area c))
  putStrLn ("Área del rectángulo: " ++ show (area r) ++ " -> " ++ clasificarArea (area r))