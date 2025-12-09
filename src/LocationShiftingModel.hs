module LocationShiftingModel where
import Data.List (intercalate)
import Numeric

type KW = Rational
type KgCO2ePerYear = Rational
type Load = Rational
type Fraction = Rational
type Factor = Rational

data LocationShiftingModelData = LSMData {
     n_n :: Rational -- number of nodes in the data centre
    ,n_hi :: Rational -- number of sites with low emissions 
    ,n_lo :: Rational -- number of sites with high emissions 
    ,c_em :: KgCO2ePerYear -- embodied carbon emissions (per node); includes embodied carbon emissions of the data centre infrastructure, scaled on the number of nodes
    ,c_hi :: KgCO2ePerYear -- carbon emissions from use of high-emissions site (per node)
    ,c_lo :: KgCO2ePerYear -- carbon emissions from use of low-emissions site
    ,lambda_hi :: Load
    ,lambda_lo :: Load
    ,gamma :: Factor -- idle power consumption factor
    ,alpha :: Fraction -- fraction of workload that can be moved
    ,beta :: Fraction -- fraction of the time that this workload can be moved    
    ,eta :: Factor -- overhead factor for emissions incurred because of location shifting (network emissions, copying of data, ...)
} deriving (Show)

showLSM lsm = 
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma alpha beta eta = lsm
        lsm_lst = [n_n,n_hi,n_lo,c_em,c_hi,c_lo,lambda_hi,lambda_lo,gamma,alpha,beta,eta]
        p_lst = [0,0,0,0,0,0,2,2,2,2,2,2]
    in 
        intercalate ", "  $ map (\(v,p) -> show $ showFFloat (Just p) (fromRational v) "") (zip lsm_lst p_lst)

showListLSM lsm = 
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma alpha beta eta = lsm
        lsm_lst = [n_n,n_hi,n_lo,c_em,c_hi,c_lo,lambda_hi,lambda_lo,gamma,alpha,beta,eta]
        p_lst = [0,0,0,0,0,0,2,2,2,2,2,2]
    in 
        map (\(v,p) -> addThousandsCommaSep $ showFFloat (Just p) (fromRational v) "") (zip lsm_lst p_lst)

addThousandsCommaSep lst =
    if (((length lst) <=3) || ('.' `elem` lst )) then lst else
    let
        len = length lst
        triplet = drop (len-3) lst 
        rest = take (len-3) lst 
        crest =  addThousandsCommaSep rest
        crlst = crest++  ","++triplet
    in
        crlst

emissionsBaseline :: LocationShiftingModelData -> KgCO2ePerYear
emissionsBaseline lsm = 
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma _ _ _ = lsm
    in
        n_n*(
        (n_hi+n_lo)*c_em
        + n_hi*(lambda_hi+(1-lambda_hi)*gamma)*c_hi
        + n_lo*(lambda_lo+(1-lambda_lo)*gamma)*c_lo
        )

        -- n_n*( lambda_hi*c_hi + lambda_lo*c_lo )

-- c_ls : the  emissions in case of location shifting
emissionsWithLocationShifting:: LocationShiftingModelData ->  KgCO2ePerYear
emissionsWithLocationShifting lsm =
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma alpha beta eta = lsm
        -- n_hi*lambda_hi*alpha <= n_lo*(1-lambda_lo)
        alphaCapped 
            | alpha > 1 = 1
            | alpha < 0 = 0
            | otherwise = alpha
        maxMovable = alphaCapped*lambda_hi*n_hi
        maxFree = (1-lambda_lo)*n_lo
        alphaEff 
            | maxMovable <= maxFree = alphaCapped
            | n_hi*lambda_hi>=maxFree = maxFree/(lambda_hi*n_hi)
            | otherwise = 1 -- so we move n_hi*lambda_hi*alphaEff  = n_hi*lambda_hi*((1-lambda_lo)/n_lo))/(lambda_hi*n_hi)=(1-lambda_lo)/n_lo
        maxFreePortion = alphaEff*lambda_hi*n_hi/n_lo 
            -- | maxMovable <= maxFree = maxMovable/n_lo
            -- | otherwise = 1-lambda_lo    
            -- maxFreePortion = maxMovable/n_lo = alphaEff*lambda_hi*n_hi/n_lo 
            -- => n_lo*(lambda_lo+maxFreePortion) = n_lo*(lambda_lo+alphaCapped*lambda_hi*n_hi/n_lo )
            -- IF alphaCapped*lambda_hi*n_hi/n_lo == 1-lambda_lo then alpha = n_lo*(1-lambda_lo)/lambda_hi*n_hi


    in
        beta*n_n*(
        (n_hi+n_lo)*c_em -- embodied carbon of all sites
        + n_hi*(lambda_hi*(1-alphaEff)+(1-lambda_hi*(1-alphaEff))*gamma)*c_hi
        + n_lo*(lambda_lo+alphaEff*lambda_hi*n_hi/n_lo+(1-lambda_lo-alphaEff*lambda_hi*n_hi/n_lo)*gamma)*c_lo
        + eta*alphaEff*(n_hi*c_hi+n_lo*c_lo)
        )
        + (1-beta)*(emissionsBaseline lsm)
{-
Case 1: alpha*beta*n_hi/n_lo > 1-lambda_lo

(lambda_hi - (n_lo/n_hi)*(1-lambda_lo)) == lambda_hi*(1-maxMovablePortion)
 (n_lo/n_hi)*(1-lambda_lo)/lambda_hi == maxMovablePortion

 maxMovablePortion = (n_lo/n_hi)*(1-lambda_lo)/lambda_hi

1 - maxMovablePortion >= 0
maxMovablePortion <= 1
 ((1-lambda_lo)/lambda_hi)*n_lo/n_hi <= 1
 n_lo*(1-lambda_lo) <= lambda_hi*n_hi 
 which would means that the free space in the low data centre must be smaller than the used space in the high data centre

 n_lo*(lambda_lo+maxFreePortion)*c_lo
 maxFreePortion = 1-lambda_lo

 Case 2: alpha*beta*n_hi/n_lo <= 1-lambda_lo

n_hi*lambda_hi*(1-alpha*beta)*c_hi

maxMovablePortion = alpha*beta
=> So what we move is maxMovablePortion*lambda_hi*n_hi

maxFreePortion = maxMovablePortion*lambda_hi*n_hi/n_lo

Simplified expressions for lambda_hi == lambda_lo and n_hi == n_lo, gamma=0, no c_em

Baseline 

        lambda*(c_hi+c_lo)
        
LocationShifting simplified     

        (2*lambda-1)*c_hi + c_lo

(lambda*(c_hi+c_lo) - ((2*lambda-1)*c_hi + c_lo))/lambda*(c_hi+c_lo)

c_lo=0

(1 - lambda)/lambda
0 => inf
0.01 => 100
.25 => 3
.5 => 1
1 => 0
-}


emissionsEmbodied :: LocationShiftingModelData ->  KgCO2ePerYear
emissionsEmbodied lsm =
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma alpha beta eta = lsm
    in
        n_n*(
        (n_hi+n_lo)*c_em -- embodied carbon of all sites
        )


-- Ideal means:
-- we ignore embodied carbon, 
-- assume idle power is 0 
-- have enough resources to move everything
-- and there is no overhead for moving

emissionsBaselineIdeal :: LocationShiftingModelData -> KgCO2ePerYear
emissionsBaselineIdeal lsm = 
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma _ _ _ = lsm
    in
        n_n*(n_hi*lambda_hi*c_hi + n_lo*lambda_lo*c_lo)

emissionsWithLocationShiftingIdeal :: LocationShiftingModelData -> KgCO2ePerYear
emissionsWithLocationShiftingIdeal lsm =
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma alpha beta eta = lsm
    in
        n_n*(n_lo*lambda_lo+n_hi*lambda_hi)*c_lo        

emissionsOverhead lsm =        
    let
        LSMData n_n n_hi n_lo c_em c_hi c_lo lambda_hi lambda_lo gamma alpha beta eta = lsm
        maxFreePortion
            | alpha*beta*n_hi/n_lo <= 1-lambda_lo = alpha*beta*n_hi/n_lo
            | otherwise = (1-lambda_lo)
        maxMovablePortion 
            | alpha*beta*n_hi/n_lo <= 1-lambda_lo = alpha*beta
            | otherwise =  ((1-lambda_lo)/lambda_hi)*n_lo/n_hi
    in
        n_n*eta*maxMovablePortion*(n_hi*c_hi+n_lo*c_lo)