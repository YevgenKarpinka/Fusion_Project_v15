codeunit 50004 "Caption Mgt."
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

    procedure SaveStreamToFile(_streamText: Text; ToFileName: Variant)
    var
        tmpTenantMedia: Record "Tenant Media";
        _inStream: inStream;
        _outStream: outStream;
    begin
        tmpTenantMedia.Content.CreateOutStream(_OutStream, TextEncoding::UTF8);
        _outStream.WriteText(_streamText);
        tmpTenantMedia.Content.CreateInStream(_inStream, TextEncoding::UTF8);
        // ToFileName := 'SampleFile.txt';
        DownloadFromStream(_inStream, 'Export', '', 'All Files (*.*)|*.*', ToFileName);
    end;

}