--necesitamos la libreria random para poder generar numeros aleatorios
import System.Random (randomRIO)

data Lado = Izquierda | Derecha deriving (Show, Eq)

mostrarLado :: Lado -> String
mostrarLado Izquierda = "IZQUIERDA"
mostrarLado Derecha   = "DERECHA"

sortearLado :: IO Lado
sortearLado = do
  n <- randomRIO (0, 1) :: IO Int
  return (if n == 0 then Izquierda else Derecha)

sortearFila :: IO Int
sortearFila = randomRIO (1, 4)

sortearAsiento :: IO Int
sortearAsiento = randomRIO (1, 4)

elegirEstudiante :: IO String
elegirEstudiante = do
  lado    <- sortearLado
  fila    <- sortearFila
  asiento <- sortearAsiento
  return ("FILA " ++ mostrarLado lado ++ " " ++ show fila ++ " - ASIENTO " ++ show asiento)

main :: IO ()
main = do
  resultado <- elegirEstudiante
  putStrLn "Sorteando participante..."
  putStrLn resultado