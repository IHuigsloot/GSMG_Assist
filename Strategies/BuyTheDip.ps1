﻿<#

INFORMATION:
    Core thought of this script is to buy when the market is about to reverse.
    We do this once a market goes below the threshold we set, see $minThreshold.
    When the market is below the threshold we validate if the market is starting to reverse.
        If we're going up then that means we might have hit support, we adjust the BEM accordingly through a calculation.
    When the market continues to go down the bot returns to its initial BEM value which should be passive until we pick up another reverse.

#>

#Default values, we want to be passive untill we get a good grip of the situation we are in.
[int] $minThreshold = -3 # I've chosen for 5 because thats a nice decrease start value, most 24h candles are 30% when moving
[int] $bemPct = -2

if ($Global:BuyTheDip_24hHistory -eq $null) {
    $Global:BuyTheDip_24hHistory = @{}
}

$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("$($market.exchange):", "")
    [int] $currentMarketValuePct = (Query-24hTicker($marketName)).priceChangePercent

    if (-not $Global:BuyTheDip_24hHistory.Contains($marketName)) {
        $Global:BuyTheDip_24hHistory[$marketName] = @{}
    }

    # 24h movements for the market
    $24hChangePct = $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"]
    $24hHistoryLast1 = $24hChangePct | Select-Object -Last 1
    $24hHistoryLast10 = $24hChangePct | Select-Object -Last 10

    # We need to have at least 5 values to somehwat estimate a good average
    if ($24hHistoryLast10.Count -gt 5) {
        [float]$24hHistoryAvg = ($24hHistoryLast10 | Measure-Object -Sum).Sum / $24hHistoryLast10.Length

        # If we're higher than our last value it means the market is going up
        # If we're higher than our minimum decrease in value
        # The current market value needs to be less or equal to the 24h history avg, if we're lower then that means we have most likely missed our buying opportunity.
        if ($currentMarketValuePct -ge $24hHistoryLast1 `
        -and $currentMarketValuePct -le $minThreshold `
        -and $currentMarketValuePct -le $24hHistoryAvg) {
            $difference = $lastMarketValuePct - $currentMarketValuePct
            $bemPct = [Math]::Abs($24hHistoryAvg - $difference)
        } 
    }

    # If we dont a lastMarketValuePct then that means there is nothing in the list, hence we add it
    # If we do have a list then we compare the last known value with our current value, if its the same we dont add it
    if ($24hHistoryLast1 -eq $null -or $24hHistoryLast1 -ne $currentMarketValuePct) {
        $Global:BuyTheDip_24hHistory[$marketName]["24hChangePct"] += @($currentMarketValuePct)
    }

    Write-Host "$marketName -> BEM $bemPct"
    #Set-GSMGSetting -Market $marketName -BemPct $bemPct
}