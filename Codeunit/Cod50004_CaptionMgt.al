codeunit 50001 "Caption Mgt."
{
    procedure GetRecordFiltersWithCaptions(locCust: Record Customer): Text;
    var
        Result: Text;
    begin
        Result := locCust.GetFilters;
        exit(Result);
    end;

    procedure GetRecordFiltersWithCaptionsPurchaseHeader(locPH: Record "Purchase Header"): Text;
    var
        Result: Text;
    begin
        Result := locPH.GetFilters;
        exit(Result);
    end;

    procedure GetItemAttributeValue(ItemAttributeName: Text[50]; ItemNo: Code[20]): Text
    var
        ItemAttr: Record "Item Attribute";
        ItemAttrValue: Record "Item Attribute Value";
        ItemAttrValMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttr.SetRange(Name, ItemAttributeName);
        ItemAttr.SetRange(Blocked, false);
        if ItemAttr.FindFirst() then
            if ItemAttrValMapping.Get(Database::Item, ItemNo, ItemAttr.ID) then
                if ItemAttrValue.Get(ItemAttrValMapping."Item Attribute ID", ItemAttrValMapping."Item Attribute Value ID") then
                    exit(ItemAttrValue.Value);
        exit('');
    end;
}