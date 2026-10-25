--!strict
-- Engine-independent adapter used directly by MarketplaceService.ProcessReceipt.
-- Grant must return success ONLY after the atomic balance+receipt write completes.
local Processor={}
function Processor.process(receipt,context)
	if type(receipt)~="table" or type(receipt.ProductId)~="number" or type(receipt.PlayerId)~="number" or receipt.PlayerId<=0 or receipt.PlayerId%1~=0 or receipt.ProductId%1~=0 or type(receipt.PurchaseId)~="string" or #receipt.PurchaseId==0 or #receipt.PurchaseId>128 then
		return "NotProcessedYet","invalid_receipt"
	end
	local product=context.Products[receipt.ProductId]
	if not product then return "NotProcessedYet","unknown_product" end
	local player=context.GetPlayer(receipt.PlayerId)
	if not player or not context.IsLoaded(player) or not context.Durable then return "NotProcessedYet","not_ready" end
	local returned,committed,status=pcall(context.Grant,player,{Kind="receipt",Id=receipt.PurchaseId,Amount=product.Coins})
	if returned and committed and (status=="ok" or status=="duplicate") then return "PurchaseGranted",status end
	return "NotProcessedYet",if returned then status else "write_error"
end
return table.freeze(Processor)
