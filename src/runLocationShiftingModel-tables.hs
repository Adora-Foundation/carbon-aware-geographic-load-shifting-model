module Main where 
import LocationShiftingModelCommon (doeCommercial,doeHPC)
import LocationShiftingModel
import Numeric
import Data.List (intercalate, transpose)



header = [
    "$n_n$",
    "$n_{hi}$",
    "$n_{lo}$",
    "Embodied carbon $c_{em}\\, (kgCO_2e/y)$",
    "Operational emissions, high-CI $c_{hi}\\, (kgCO_2e/y)$",
    "Operational emissions, low-CI $c_{lo}\\, (kgCO_2e/y)$",
    "$\\lambda_{hi}$",
    "$\\lambda_{lo}$",
    "$\\gamma$",
    "$\\alpha$",
    "$\\beta$",
    "$\\eta$", 
    "\\emph{overhead} ($tCO_2e/y$)", 
    "Embodied ($tCO_2e/y$)",
    "Baseline ($tCO_2e/y$)", 
    "Geographic load shifting ($tCO_2e/y$)", 
    "Emission reduction (\\%)"
    ]


res_table_commercial = let
        rows = map (\lsm_commercial -> 
                let
                    c_b_commercial = emissionsBaseline lsm_commercial
                    c_ls_commercial = emissionsWithLocationShifting lsm_commercial
                    c_oh_commercial = emissionsOverhead lsm_commercial
                    c_emb_commercial = emissionsEmbodied lsm_commercial
                    red_commercial = 100*(c_b_commercial - c_ls_commercial)/c_b_commercial
                in 
                    (showListLSM lsm_commercial)++[
                        addThousandsCommaSep $ (showFFloat (Just 0) (fromRational $ c_oh_commercial/1000) ""),
                        addThousandsCommaSep $ (showFFloat (Just 0) (fromRational $ c_emb_commercial/1000) ""),
                        addThousandsCommaSep $ (showFFloat (Just 0) (fromRational $ c_b_commercial/1000) ""),
                        addThousandsCommaSep $ (showFFloat (Just 0) (fromRational $ c_ls_commercial/1000) ""),
                        (showFFloat (Just 1) (fromRational red_commercial) "\\%") 
                    ]
            ) doeCommercial
    in
        transpose (header:rows)


res_table_HPC = let        
        rows = map (\lsm_HPC ->
                let
                    c_b_HPC = emissionsBaseline lsm_HPC
                    c_ls_HPC = emissionsWithLocationShifting lsm_HPC
                    c_oh_HPC = emissionsOverhead lsm_HPC
                    c_emb_HPC = emissionsEmbodied lsm_HPC
                    red_HPC = 100*(c_b_HPC - c_ls_HPC)/c_b_HPC            
                in
                    (showListLSM lsm_HPC)++[
                        addThousandsCommaSep $ (showFFloat (Just 0)  (fromRational $ c_oh_HPC/1000) ""),
                        addThousandsCommaSep $ (showFFloat (Just 0)  (fromRational $ c_emb_HPC/1000) ""),
                        addThousandsCommaSep $ (showFFloat (Just 0)  (fromRational $ c_b_HPC/1000) ""),
                        addThousandsCommaSep $ (showFFloat (Just 0) (fromRational $ c_ls_HPC/1000) ""),
                        (showFFloat (Just 1) (fromRational red_HPC) "\\%")
                    ]
                
            ) doeHPC
    in
        transpose (header:rows)

main = do
    putStrLn "\\textbf{AI Data Centre Parameters} & \\textbf{Scenario 1 (Solar)} & \\textbf{Scenario 2 (Wind)}\\tabularnewline\n\\hline"
    mapM (\row -> putStrLn $ "\\hline\n" ++(intercalate " & "  row)++"\\tabularnewline") res_table_commercial
    putStrLn "\\hline\n"
    putStrLn "\\textbf{HPC Centre Parameters} & \\textbf{Scenario 1} & \\textbf{Scenario 2} & \\textbf{Scenario 3} & \\textbf{Scenario 4} & \\textbf{Scenario 5}\\tabularnewline\n\\hline"
    mapM (\row -> putStrLn $ "\\hline\n" ++(intercalate " & "  row)++"\\tabularnewline") res_table_HPC
    putStrLn "\\hline\n"
