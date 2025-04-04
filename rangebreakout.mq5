#property copyright "Amon Kiprono"
#property description "A momentum rider expert advisor that uses a set of two simple indicators to ride short term momentum"
#property version "1.00"


// Trade (hedging)
#include <mql5book_1\TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

// Money management
#include <mql5book_1\MoneyManagement.mqh>

#include <mql5book_1\Pending.mqh>
CPending Pending;


#include <mql5book_1/Timer.mqh>
CTimer Timer;

// Timer
#include <mql5book_1\Timer.mqh>
CNewBar NewBar;

#include <mql5book_1\Price.mqh>
CBars Bar;
CBars Price;


// Indicators 
#include <mql5book_1\Indicators.mqh>
CiSTDEV Stdev;
CiATR ATR;

#include  <mql5book_1\TrailingStops.mqh>
CTrailing TrailStop;

//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input ulong Slippage = 5;
input int MagicNumber = 123;

sinput string MoneyManager; 	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 4;
input double FixedVolume = 0.1;

input int StopLoss = 100;
input int TakeProfit = 400;
input int lookBars = 5;
input double profitRatio = 0.002;

// Timer inputs
input bool UseTimer = true;
input int StartHour = 3;
input int StartMinute = 30;
input int EndHour = 19;
input int EndMinute = 0;
input bool UseLocalTime = true;


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

// Store order tickets

bool tradeExist = false;
bool stdevSignal = false;
bool orderPlaced = false;

double initPrice = 0;

double buyStopLoss, sellStopLoss;

//double startPips = startPoints*SymbolInfoDouble(_Symbol, SYMBOL_POINT);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
		
	// Set deviation and magic number
	Trade.Deviation(Slippage);
	Trade.MagicNumber(MagicNumber);
	
		
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   
   bool minuteBar = true;
	minuteBar = NewBar.CheckNewBar(_Symbol,PERIOD_M1);
	
	
	
	if(minuteBar == true)
   {
   	// Update daily bars
   	ulong glBuyTicket = 0, glSellTicket = 0;
   	int barShift = 0;
   	
   	
   	double curProfit = MathAbs(SymbolInfoDouble(_Symbol, SYMBOL_ASK) - initPrice);
   	
   	double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   	double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   	double close = (ask + bid)/2;
   			
   	double openBuyPrice = HighestHigh(_Symbol, _Period, lookBars);
   	double openSellPrice = LowestLow(_Symbol, _Period, lookBars);
   	
   		
   	tradeExist = CheckExistTrade();
   	bool timerOn = true;
   	if(UseTimer == true)
      {
         timerOn = Timer.DailyTimer(StartHour, StartMinute, EndHour, EndMinute, UseLocalTime);
         
      }
      
      if(timerOn == false)
      {
         CloseAllPositions();
         DeletePending();
         orderPlaced = false;
              
      }
      
   	// Order placement
   	if(timerOn == true)
   	{
   		
		
   		// Open buy order
   		if(orderPlaced == false)
   		{
   			      					
   			// Open buy order
   			buyStopLoss = openSellPrice; 
   			
   			// Money management
      		double tradeVolume;
      		double stopPoints = StopPriceToPoints(_Symbol, buyStopLoss, openBuyPrice);
      		if(UseMoneyManagement == true) tradeVolume = MoneyManagement(_Symbol,FixedVolume,RiskPercent,stopPoints);
      		else tradeVolume = VerifyVolume(_Symbol,FixedVolume); 
      				 			
         	double buyTakeProfit = BuyTakeProfit(_Symbol,TakeProfit,openBuyPrice);
      		if(ask < openBuyPrice)   			
   			   Trade.BuyStop(_Symbol, tradeVolume, openBuyPrice,buyStopLoss);
      		
   			// open sell order
   			sellStopLoss = openBuyPrice;   			
      		double sellTakeProfit = SellTakeProfit(_Symbol,TakeProfit,openSellPrice);
      		if(bid > openSellPrice)   		
   			   Trade.SellStop(_Symbol, tradeVolume, openSellPrice,sellStopLoss);
   			
   			initPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   						
   			orderPlaced = true;
   		}
   		 
   	} // Order placement end
   	
   	
      
   	if(PositionSelect(_Symbol) == true)
   	{
   	   
   	   //Sleep(60000);
   	   
   	   
   	   
   	   long positionType = PositionGetInteger(POSITION_TYPE);
   	   
   	   if(positionType == POSITION_TYPE_BUY) glBuyTicket = PositionGetInteger(POSITION_TICKET);
   	   if(positionType == POSITION_TYPE_SELL) glSellTicket = PositionGetInteger(POSITION_TICKET);
   	}
   	
   	
   	/* breakeven and trailstop code		
   	if(glBuyTicket != 0 && curProfit > profitRatio*close)
   	{
   	   //double breakEven = trailPoints;
   	   //double minProfit = minProfitFactor*StopLoss;
   	   
   	   BreakEven(glBuyTicket, curProfit, 0.5*curProfit);
   	   //TrailingStop(glBuyTicket, trailPoints, minProfit);
   	   
   	  
   	}
   	else if(glSellTicket != 0 && curProfit > profitRatio*close)
   	{
   	   //double breakEven = trailPoints;
   	   //double minProfit = minProfitFactor*StopLoss;
   	   
   	   BreakEven(glSellTicket, curProfit, 0.5*curProfit);
   	   //TrailingStop(glSellTicket, trailPoints, minProfit);
   	   		   
   	}
   	
   		*/
   }	
}

bool TrailingStop(ulong pTicket,double pTrailPoints, double pMinProfit=0,int pStep=20)
{
	
	PositionSelectByTicket(pTicket);
				
	long posType = PositionGetInteger(POSITION_TYPE);
	double currentStop = PositionGetDouble(POSITION_SL);
	double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
	int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
	
	
	double minProfit = pMinProfit * _Point;
	double trailStop = pTrailPoints * _Point;
	currentStop = NormalizeDouble(currentStop,digits);
		
	double trailStopPrice;
	double currentProfit;
	double step = pStep*_Point;
	
	bool modify;
	if(posType == POSITION_TYPE_BUY)
	{
	   trailStopPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID) - trailStop;
	   trailStopPrice = NormalizeDouble(trailStopPrice, digits);
	   currentProfit = SymbolInfoDouble(_Symbol,SYMBOL_BID) - openPrice;
	   if(trailStopPrice > currentStop + step && currentProfit >= minProfit)
	   {
	      modify = Trade.ModifyPosition(pTicket, trailStopPrice);
	      
	   }
	}
	else if(posType == POSITION_TYPE_SELL)
	{
	   trailStopPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + trailStop;
	   trailStopPrice = NormalizeDouble(trailStopPrice, digits);
	   currentProfit = openPrice - SymbolInfoDouble(_Symbol,SYMBOL_ASK);
	   if(trailStopPrice < currentStop - step && currentProfit >= minProfit)
	   {
	      modify = Trade.ModifyPosition(pTicket, trailStopPrice);
	   }
	}
	return(modify);
}

ulong CheckExistTrade()
{
   bool trade = false;
   int positions = Positions.TotalPositions(MagicNumber);
   
   if(positions == 0) trade = false;
   else trade = true;
   
   return(trade);
}

bool BreakEven(ulong pTicket,double pBreakEven,double pLockProfit)
{
	PositionSelectByTicket(pTicket);
			
	long posType = PositionGetInteger(POSITION_TYPE);
	double currentSL = PositionGetDouble(POSITION_SL);
	double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
			
	double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
	int digits = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
		
	double breakEvenStop;
	double currentProfit;
		
	double bid, ask;
	bool modify;
	
	if(posType == POSITION_TYPE_BUY)
	{
		bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
		breakEvenStop = openPrice + (pLockProfit);// * point);
		currentProfit = bid - openPrice;
				
		breakEvenStop = NormalizeDouble(breakEvenStop, digits);
		currentProfit = NormalizeDouble(currentProfit, digits);
				
		if(currentSL < breakEvenStop && currentProfit > pBreakEven * point) 
		{
			modify = Trade.ModifyPosition(pTicket, breakEvenStop);
		}
	}
	else if(posType == POSITION_TYPE_SELL)
	{
		ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
		breakEvenStop = openPrice - (pLockProfit);// * point);
		currentProfit = openPrice - ask;
				
		breakEvenStop = NormalizeDouble(breakEvenStop, digits);
		currentProfit = NormalizeDouble(currentProfit, digits);
				
		if(currentSL > breakEvenStop && currentProfit > pBreakEven * point)
		{
			modify = Trade.ModifyPosition(pTicket, breakEvenStop);
		}
				
	}
	return(modify);
}
bool CloseAllPositions(void)
{
   ulong tickets[];
   bool close = false;
   Positions.GetTickets(MagicNumber, tickets);
   for(int i=0; i<ArraySize(tickets); i++)
   {
      ulong ticket = tickets[i];
      if(ticket > 0)
        close = Trade.Close(ticket);
   }
   return(close);
}

void DeletePending()
{
   ulong tickets[];
   Pending.GetTickets(_Symbol, tickets);
   for(int i=0; i<ArraySize(tickets); i++)
   {
      ulong ticket = tickets[i];
      if(ticket > 0)
         Trade.Delete(ticket);
   }
}