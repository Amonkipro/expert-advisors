//+------------------------------------------------------------------+
//|                                                    dual grid.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Mql5Book\TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

#include <Mql5Book\Timer.mqh>

input int gridPoints = 100;
input double volume = 0.01;
input int MagicNumber = 12345;

int gridSize = gridPoints*(SymbolInfoDouble(_Symbol, SYMBOL_POINT));
	
ulong initBuyTicket, initSellTicket;
double buyTakeProfit = BuyTakeProfit(_Symbol, gridPoints);
double sellTakeProfit = SellTakeProfit(_Symbol, gridPoints);
bool level_1=false, level_2=false, level_3=false, level_4=false;
bool level_11=false, level_12=false, level_13=false, level_14=false;
double initOpenBuyPrice = CheckCurrPrice();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
      Trade.MagicNumber(MagicNumber);
        
      initBuyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      initSellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ulong buyTicket = 0, sellTicket = 0;		
   
	double currPrice = CheckCurrPrice();
	double diffPrice = GetDiffPrice(currPrice, initOpenBuyPrice);
	
		
   if(diffPrice >= gridSize && diffPrice < 2*gridSize && level_1 == false)
   {    
      buyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      sellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
      level_1 = true;
   }
   else if(diffPrice >= 2*gridSize && diffPrice < 3*gridSize && level_2 == false)
   {      
      buyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      sellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
      level_2 = true;
   }
   
   else if(diffPrice == 3*gridSize && diffPrice < 4*gridSize && level_3 == false)
   {      
      buyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      sellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
      level_3 = true;
   }
   
   else if(diffPrice >= 4*gridSize)
   {
      level_4 = true;
      bool close = CloseAllPositions();
   }
   
   else if(diffPrice <= -gridSize && diffPrice > -2*gridSize && level_11 == false)
   {
      buyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      sellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
      level_11 = true;
   }
   else if(diffPrice <= -2*gridSize && diffPrice > -3*gridSize && level_12 == false)
   {
      buyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      sellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
      level_12 = true;
   }
   else if(diffPrice <= -3*gridSize && diffPrice > -4*gridSize && level_11 == false)
   {
      buyTicket = Trade.Buy(_Symbol, volume, 0, buyTakeProfit);
      sellTicket = Trade.Sell(_Symbol, volume, 0, sellTakeProfit);
      level_13 = true;
   }
   else if(diffPrice >= -4*gridSize)
   {
      level_14 = true;
      bool close = CloseAllPositions();
   }
   
    
   if(level_1 == true && diffPrice <= 0)
   {
      bool close = CloseAllPositions();
   }
   else if(level_2 == true && diffPrice <= gridSize)
   {
      bool close = CloseAllPositions();
   }
   else if(level_3 == true && diffPrice <= 2*gridSize)
   {
      bool close = CloseAllPositions();
   }    
   else if(level_11 == true && diffPrice >= 0)
   {
      bool close = CloseAllPositions();
   }
   else if(level_12 == true && diffPrice >= -gridSize)
   {
      bool close = CloseAllPositions();
   }
   else if(level_13 == true && diffPrice >= -2*gridSize)
   {
      bool close = CloseAllPositions();
   }
   
  }
//+------------------------------------------------------------------+

double GetDiffPrice(double pcurrPrice, double popenPrice)
{
   double diffPrice = pcurrPrice - popenPrice;
   
   return(diffPrice);
}

bool CloseAllPositions(void)
{
   ulong tickets[];
   bool close = false;
   Positions.GetTickets(MagicNumber, tickets);
   for(int i=0; i<ArraySize(tickets); i++)
   {
      ulong ticket = tickets[i];
      close = Trade.Close(ticket);
   }
   return(close);
}


