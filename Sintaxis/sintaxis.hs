-- sintaxis.hs
-- Un ejemplo por cada tema de la seccion "Sintaxis" de la presentacion.

-- ============================================================
-- 1. VARIABLES: no existen las mutables; solo hay definiciones
-- ============================================================
lenguaje :: String
lenguaje = "Haskell"

anio :: Int
anio = 1990

-- Esto NO se puede hacer (error al compilar):
--   anio = anio + 1

-- ============================================================
-- 2. FUNCIONES: primero el tipo, luego la implementacion
-- ============================================================
cuadrado :: Int -> Int
cuadrado x = x * x

sumar :: Int -> Int -> Int
sumar x y = x + y

-- Primera clase (1): una funcion se recibe como argumento
aplicarDosVeces :: (Int -> Int) -> Int -> Int
aplicarDosVeces f x = f (f x)

-- Primera clase (2): una funcion se devuelve como resultado
sumador :: Int -> (Int -> Int)
sumador n = \x -> x + n        -- \x -> ... es una funcion lambda

-- ============================================================
-- 3. PARAMETROS: se pasan por valor y no se pueden modificar
-- ============================================================
duplicar :: Int -> Int
duplicar n = n * 2             -- n no cambia; se devuelve un valor nuevo

-- ============================================================
-- 4. CICLOS: no hay for ni while; se usa recursion
-- ============================================================
factorial :: Integer -> Integer
factorial 0 = 1                          -- caso base
factorial n = n * factorial (n - 1)      -- caso recursivo

sumaLista :: [Int] -> Int
sumaLista []     = 0                     -- lista vacia
sumaLista (x:xs) = x + sumaLista xs      -- x = primero, xs = el resto

cuentaRegresiva :: Int -> [Int]
cuentaRegresiva 0 = [0]
cuentaRegresiva n = n : cuentaRegresiva (n - 1)

-- ============================================================
-- 5. LIST COMPREHENSIONS: forma compacta de construir listas
-- ============================================================
cuadradosImpares :: [Int]
cuadradosImpares = [x * x | x <- [1..5], odd x]

parejas :: [(Int, Char)]
parejas = [(n, c) | n <- [1..2], c <- "ab"]

-- ============================================================
-- 6. ESTRUCTURAS DE CONTROL
-- ============================================================

-- If-then-else (siempre lleva else: es una expresion)
paridad :: Int -> String
paridad n = if even n then "par" else "impar"

-- Guards: una cadena de condiciones
signo :: Int -> String
signo n
  | n > 0     = "positivo"
  | n < 0     = "negativo"
  | otherwise = "cero"

-- Pattern matching: una ecuacion por cada forma del dato
mensajes :: Int -> String
mensajes 0 = "No tienes mensajes"
mensajes 1 = "Tienes 1 mensaje"
mensajes n = "Tienes " ++ show n ++ " mensajes"

describirLista :: [Int] -> String
describirLista []    = "lista vacia"
describirLista [x]   = "un solo elemento: " ++ show x
describirLista (x:_) = "empieza con " ++ show x

-- ============================================================
-- 7. TIPOS DE DATOS ("clases"): datos algebraicos
-- ============================================================
data Persona = Persona
  { pNombre :: String
  , pEdad   :: Int
  } deriving Show

data Figura = Circulo Double | Rectangulo Double Double

area :: Figura -> Double
area (Circulo r)      = pi * r * r
area (Rectangulo b h) = b * h

-- ============================================================
-- 8. "HERENCIA" -> TYPE CLASSES
-- ============================================================
class Saludable a where
  saludar :: a -> String

instance Saludable Persona where
  saludar p = "Hola, soy " ++ pNombre p ++ " y tengo " ++ show (pEdad p) ++ " anios"

data Perro = Perro String

instance Saludable Perro where
  saludar (Perro nombre) = "Guau, me llamo " ++ nombre

-- ============================================================
-- PROGRAMA PRINCIPAL: muestra el resultado de cada tema
-- ============================================================
titulo :: String -> IO ()
titulo t = putStrLn ("\n--- " ++ t ++ " ---")

main :: IO ()
main = do
  titulo "1. Variables"
  putStrLn (lenguaje ++ " nacio en " ++ show anio)

  titulo "2. Funciones"
  print (cuadrado 4)                       -- 16
  print (sumar 3 5)                        -- 8
  print (aplicarDosVeces cuadrado 3)       -- (3^2)^2 = 81
  print (sumador 10 5)                     -- 15
  print (map (sumador 1) [1, 2, 3])        -- [2,3,4]

  titulo "3. Parametros"
  let n = 7
  print (duplicar n)                       -- 14
  print n                                  -- sigue siendo 7

  titulo "4. Ciclos (recursion, map, filter, foldr)"
  print (factorial 5)                      -- 120
  print (sumaLista [1, 2, 3, 4])           -- 10
  print (cuentaRegresiva 5)                -- [5,4,3,2,1,0]
  print (map (* 2) [1 .. 5])               -- [2,4,6,8,10]
  print (filter even [1 .. 10])            -- [2,4,6,8,10]
  print (foldr (+) 0 [1 .. 10])            -- 55

  titulo "5. List comprehensions"
  print cuadradosImpares                   -- [1,9,25]
  print parejas                            -- [(1,'a'),(1,'b'),(2,'a'),(2,'b')]

  titulo "6. Estructuras de control"
  putStrLn (paridad 7)                     -- impar
  putStrLn (signo (-3))                    -- negativo
  putStrLn (mensajes 0)
  putStrLn (mensajes 1)
  putStrLn (mensajes 5)
  putStrLn (describirLista [])
  putStrLn (describirLista [9])
  putStrLn (describirLista [4, 5, 6])

  titulo "7. Tipos de datos"
  let ana = Persona "Ana" 20
  print ana
  print (pEdad ana)
  print (area (Circulo 1.0))               -- 3.141592653589793
  print (area (Rectangulo 4 6))            -- 24.0

  titulo "8. Type classes"
  putStrLn (saludar ana)
  putStrLn (saludar (Perro "Rex"))