-- calculadora.hs
-- Calculadora con interfaz de menu en la terminal.
-- Compilar: ghc -o calculadora calculadora.hs
-- Ejecutar: .\calculadora

module Main where

import Data.Char (toLower)
import System.IO (BufferMode (NoBuffering), hSetBuffering, stdout)
import Text.Read (readMaybe)

-- ------------------------------------------------------------
-- Tipos de datos
-- ------------------------------------------------------------

-- Un tipo de dato algebraico con todas las operaciones posibles
data Operacion
  = Suma
  | Resta
  | Multiplicacion
  | Division
  | Potencia
  | Modulo
  | RaizCuadrada
  deriving (Show, Eq)

-- El historial es una lista de textos
type Historial = [String]

-- ------------------------------------------------------------
-- Logica pura (sin IO)
-- ------------------------------------------------------------

simbolo :: Operacion -> String
simbolo Suma           = "+"
simbolo Resta          = "-"
simbolo Multiplicacion = "*"
simbolo Division       = "/"
simbolo Potencia       = "^"
simbolo Modulo         = "%"
simbolo RaizCuadrada   = "sqrt"

esUnaria :: Operacion -> Bool
esUnaria RaizCuadrada = True
esUnaria _            = False

-- Either: Left = error con mensaje, Right = resultado correcto
aplicar :: Operacion -> Double -> Double -> Either String Double
aplicar Suma           a b = Right (a + b)
aplicar Resta          a b = Right (a - b)
aplicar Multiplicacion a b = Right (a * b)
aplicar Division       _ 0 = Left "No se puede dividir entre cero"
aplicar Division       a b = Right (a / b)
aplicar Potencia       a b = Right (a ** b)
aplicar Modulo         a b
  | b == 0    = Left "No se puede calcular el modulo con cero"
  | otherwise = Right (a - b * fromIntegral (floor (a / b) :: Integer))
aplicar RaizCuadrada   a _
  | a < 0     = Left "No existe la raiz cuadrada real de un negativo"
  | otherwise = Right (sqrt a)

-- Rechaza resultados que no son numeros (por ejemplo (-8) ^ 0.5)
validar :: Double -> Either String Double
validar x
  | isNaN x      = Left "El resultado no esta definido"
  | isInfinite x = Left "El resultado es demasiado grande"
  | otherwise    = Right x

-- Muestra 15.0 como 15, y deja los decimales cuando hacen falta
formatear :: Double -> String
formatear x
  | x == fromIntegral entero && abs x < 1e15 = show entero
  | otherwise                                = show x
  where
    entero = round x :: Integer

describir :: Operacion -> Double -> Double -> Double -> String
describir op a b r
  | esUnaria op = simbolo op ++ "(" ++ formatear a ++ ") = " ++ formatear r
  | otherwise   = formatear a ++ " " ++ simbolo op ++ " " ++ formatear b
                  ++ " = " ++ formatear r

opcionAOperacion :: String -> Maybe Operacion
opcionAOperacion "1" = Just Suma
opcionAOperacion "2" = Just Resta
opcionAOperacion "3" = Just Multiplicacion
opcionAOperacion "4" = Just Division
opcionAOperacion "5" = Just Potencia
opcionAOperacion "6" = Just Modulo
opcionAOperacion "7" = Just RaizCuadrada
opcionAOperacion _   = Nothing

-- ------------------------------------------------------------
-- Interfaz de terminal (IO)
-- ------------------------------------------------------------

mostrarMenu :: Maybe Double -> IO ()
mostrarMenu ultimo = do
  putStrLn ""
  putStrLn "+----------------------------------------+"
  putStrLn "|        CALCULADORA EN HASKELL          |"
  putStrLn "+----------------------------------------+"
  putStrLn "|  1. Suma              (a + b)          |"
  putStrLn "|  2. Resta             (a - b)          |"
  putStrLn "|  3. Multiplicacion    (a * b)          |"
  putStrLn "|  4. Division          (a / b)          |"
  putStrLn "|  5. Potencia          (a ^ b)          |"
  putStrLn "|  6. Modulo            (a % b)          |"
  putStrLn "|  7. Raiz cuadrada     (sqrt a)         |"
  putStrLn "|  8. Ver historial                      |"
  putStrLn "|  9. Borrar historial                   |"
  putStrLn "|  0. Salir                              |"
  putStrLn "+----------------------------------------+"
  case ultimo of
    Nothing -> putStrLn "  Ultimo resultado: (ninguno)"
    Just r  -> putStrLn ("  Ultimo resultado: " ++ formatear r
                         ++ "   (escribe ans para usarlo)")

mostrarHistorial :: Historial -> IO ()
mostrarHistorial [] = putStrLn "El historial esta vacio."
mostrarHistorial h  = do
  putStrLn "--- Historial (del mas reciente al mas antiguo) ---"
  mapM_ putStrLn (zipWith (\i l -> show i ++ ". " ++ l) [1 :: Int ..] h)

-- Pide un numero y repite la pregunta hasta que sea valido.
-- Acepta "ans" para reutilizar el ultimo resultado y coma como decimal.
leerNumero :: Maybe Double -> String -> IO Double
leerNumero ultimo mensaje = do
  putStr mensaje
  texto <- getLine
  let limpio = map toLower (concat (words texto))
  case (limpio, ultimo) of
    ("ans", Just x) -> return x
    _ -> case readMaybe (map coma limpio) of
      Just n  -> return n
      Nothing -> do
        putStrLn "  Eso no es un numero valido. Intenta de nuevo."
        leerNumero ultimo mensaje
  where
    coma ',' = '.'
    coma c   = c

-- El "ciclo" del programa es recursion: el estado (historial y ultimo
-- resultado) se pasa como parametros en cada vuelta, sin variables mutables.
bucle :: Historial -> Maybe Double -> IO ()
bucle historial ultimo = do
  mostrarMenu ultimo
  putStr "Elige una opcion: "
  opcion <- getLine
  case concat (words opcion) of
    "0" -> putStrLn "Hasta luego!"
    "8" -> mostrarHistorial historial >> bucle historial ultimo
    "9" -> putStrLn "Historial borrado." >> bucle [] ultimo
    otra -> case opcionAOperacion otra of
      Nothing -> do
        putStrLn "Opcion no valida. Elige un numero del 0 al 9."
        bucle historial ultimo
      Just op -> do
        a <- leerNumero ultimo "Primer numero:  "
        b <- if esUnaria op
               then return 0
               else leerNumero ultimo "Segundo numero: "
        case aplicar op a b >>= validar of
          Left err -> do
            putStrLn ("  Error: " ++ err)
            bucle historial ultimo
          Right r -> do
            let linea = describir op a b r
            putStrLn ("  >> " ++ linea)
            bucle (linea : historial) (Just r)

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  bucle [] Nothing