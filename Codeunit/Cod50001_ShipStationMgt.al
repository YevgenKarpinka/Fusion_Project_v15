codeunit 50001 "ShipStation Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure SetTestMode(_testMode: Boolean)
    begin
        testMode := _testMode;
    end;

    procedure Connect2eShop(SPCode: Code[20]; Body2Request: Text; newURL: Text; var IsSuccessStatusCode: Boolean): Text
    var
        SourceParameters: Record "Source Parameters";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Client: HttpClient;
        responseText: Text;
    begin
        SourceParameters.Get(SPCode);

        RequestMessage.Method := Format(SourceParameters."FSp RestMethod");
        if newURL = '' then
            RequestMessage.SetRequestUri(SourceParameters."FSp URL")
        else
            RequestMessage.SetRequestUri(StrSubstNo('%1%2', SourceParameters."FSp URL", newURL));

        RequestMessage.GetHeaders(Headers);

        if SourceParameters."FSp RestMethod" = SourceParameters."FSp RestMethod"::POST then begin
            if SPCode = 'LOGIN2ESHOP' then begin
                Body2Request := StrSubstNo('%1=%2&%3=%4', 'email', SourceParameters."FSp UserName", 'password', SourceParameters."FSp Password");
            end;
            RequestMessage.Content.WriteFrom(Body2Request);
            RequestMessage.Content.GetHeaders(Headers);
            if SourceParameters."FSp ContentType" <> 0 then begin
                Headers.Remove('Content-Type');
                Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
            end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content.ReadAs(responseText);
        IsSuccessStatusCode := ResponseMessage.IsSuccessStatusCode();
        exit(responseText);
    end;

    procedure AddProduct2eShop(Body2Request: Text; var IsSuccessStatusCode: Boolean; var responseText: Text)
    begin
        if globalToken = '' then
            globalToken := DelChr(Connect2eShop('LOGIN2ESHOP', '', '', IsSuccessStatusCode), '<>', '"');
        if not IsSuccessStatusCode then begin
            responseText := globalToken;
            exit;
        end;
        responseText := Connect2eShop('ADDPRODUCT2ESHOP', Body2Request, globalToken, IsSuccessStatusCode);
    end;

    procedure Connect2ShipStation(SPCode: Integer; Body2Request: Text; newURL: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        SourceParameters: Record "Source Parameters";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Client: HttpClient;
        JSText: Text;
        JSObject: JsonObject;
        errMessage: Text;
        errExceptionMessage: Text;
        _InStream: InStream;
        _OutStream: OutStream;
    begin
        SourceParameters.SetCurrentKey("FSp Event");
        SourceParameters.SetRange("FSp Event", SPCode);
        SourceParameters.FindSet(false, false);

        RequestMessage.Method := Format(SourceParameters."FSp RestMethod");
        if newURL = '' then
            RequestMessage.SetRequestUri(SourceParameters."FSp URL")
        else
            RequestMessage.SetRequestUri(StrSubstNo('%1%2', SourceParameters."FSp URL", newURL));

        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', SourceParameters."FSp Accept");
        if (SourceParameters."FSp AuthorizationFrameworkType" = SourceParameters."FSp AuthorizationFrameworkType"::OAuth2)
            and (SourceParameters."FSp AuthorizationToken" <> '') then begin
            Headers.Add('Authorization', SourceParameters."FSp AuthorizationToken");
        end else
            if SourceParameters."FSp UserName" <> '' then begin
                Headers.Add('Authorization', StrSubstNo('Basic %1',
                            Base64Convert.ToBase64(StrSubstNo('%1:%2', SourceParameters."FSp UserName", SourceParameters."FSp Password"))));
            end;

        Headers.Add('If-Match', SourceParameters."FSp ETag");

        if SourceParameters."FSp RestMethod" = SourceParameters."FSp RestMethod"::POST then begin
            RequestMessage.Content.WriteFrom(Body2Request);
            RequestMessage.Content.GetHeaders(Headers);
            if SourceParameters."FSp ContentType" <> 0 then begin
                Headers.Remove('Content-Type');
                Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
            end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        ResponseMessage.Content.ReadAs(JSText);
        If ResponseMessage.IsSuccessStatusCode() then exit(JSText);

        JSObject.ReadFrom(JSText);
        errMessage := GetJSToken(JSObject, 'Message').AsValue().AsText();
        errExceptionMessage := GetJSToken(JSObject, 'ExceptionMessage').AsValue().AsText();
        Error('Web service returned error:\\Status code: %1\Description: %2\Message: %3\Exception Message: %4\Body Request:\%5',
            ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), errMessage, errExceptionMessage, Body2Request);

    end;

    procedure GetOrdersFromShipStation(): Text
    var
        JSText: Text;
        JSObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        txtOrders: Text;
        _SH: Record "Sales Header";
        txtMessage: TextConst ENU = 'Order(s) Updated:\ %1', RUS = 'Заказ(ы) обновлен(ы):\ %1';
    begin
        JSText := Connect2ShipStation(1, '', '');
        JSObject.ReadFrom(JSText);
        OrdersJSArray := GetJSToken(JSObject, 'orders').AsArray();

        for Counter := 0 to OrdersJSArray.Count - 1 do begin
            OrdersJSArray.Get(Counter, OrderJSToken);
            JSObject := OrderJSToken.AsObject();
            if _SH.Get(_SH."Document Type"::Order, GetJSToken(JSObject, 'orderNumber').AsValue().AsText()) then begin
                UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);

                if txtOrders = '' then
                    txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText()
                else
                    txtOrders += '|' + GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
            end;

        end;
        Message(txtMessage, txtOrders);

        exit(txtOrders);
    end;

    procedure GetOrderFromShipStation(): Text
    var
        JSText: Text;
        JSObject: JsonObject;
        txtOrders: Text;
        _SH: Record "Sales Header";
    begin
        // Get Order from Shipstation to Fill Variables
        JSText := Connect2ShipStation(1, '', StrSubstNo('/%1', _SH."ShipStation Order ID"));

        JSObject.ReadFrom(JSText);

        txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
        if _SH.Get(_SH."Document Type"::Order, GetJSToken(JSObject, 'orderNumber').AsValue().AsText()) then
            UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);
    end;

    local procedure GetShippingAgentService(_ServiceCode: Text[100]; _CarrierCode: Text[50]): Code[10]
    var
        _SAS: Record "Shipping Agent Services";
    begin
        _SAS.SetCurrentKey("SS Code", "SS Carrier Code");
        _SAS.SetRange("SS Carrier Code", _CarrierCode);
        _SAS.SetRange("SS Code", _ServiceCode);
        if _SAS.FindFirst() then
            exit(_SAS.Code);

        GetServicesFromShipStation(_CarrierCode);
        _SAS.FindFirst();
        exit(_SAS.Code);
    end;

    local procedure GetShippingAgent(_CarrierCode: Text[50]): Code[10]
    var
        _SA: Record "Shipping Agent";
    begin
        _SA.SetCurrentKey("SS Code");
        _SA.SetRange("SS Code", _CarrierCode);
        if _SA.FindFirst() then
            exit(_SA.Code)
        else
            exit(GetCarrierFromShipStation(_CarrierCode));
    end;

    procedure CreateOrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        _Cust: Record Customer;
        JSText: Text;
        JSObjectHeader: JsonObject;
        jsonTagsArray: JsonArray;
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);

        _Cust.Get(_SH."Sell-to Customer No.");
        JSObjectHeader.Add('orderNumber', _SH."No.");
        if _SH."ShipStation Order Key" <> '' then
            JSObjectHeader.Add('orderKey', _SH."ShipStation Order Key");
        JSObjectHeader.Add('orderDate', Date2Text4JSON(_SH."Posting Date"));
        JSObjectHeader.Add('paymentDate', Date2Text4JSON(_SH."Prepayment Due Date"));
        JSObjectHeader.Add('shipByDate', Date2Text4JSON(_SH."Shipment Date"));
        JSObjectHeader.Add('orderStatus', lblAwaitingShipment);
        JSObjectHeader.Add('customerUsername', _Cust."E-Mail");
        JSObjectHeader.Add('customerEmail', _Cust."E-Mail");
        JSObjectHeader.Add('billTo', jsonBillToFromSH(_SH."No."));
        JSObjectHeader.Add('shipTo', jsonShipToFromSH(_SH."No."));
        JSObjectHeader.Add('items', jsonItemsFromSL(_SH."No."));

        // uncomment when dimensions will be solution
        // JSObjectHeader.Add('dimensions', jsonDimentionsFromAttributeValue(_SH."No."));

        // Carrier and Service are read only
        // JSObjectHeader.Add('carrierCode', GetCarrierCodeByAgentCode(_SH."Shipping Agent Code"));
        // JSObjectHeader.Add('serviceCode', GetServiceCodeByAgentServiceCode(_SH."Shipping Agent Code", _SH."Shipping Agent Service Code"));

        // Clear(jsonTagsArray);
        JSObjectHeader.Add('tagIds', jsonTagsArray);
        JSObjectHeader.WriteTo(JSText);

        JSText := Connect2ShipStation(2, JSText, '');

        // update Sales Header from ShipStation
        JSObjectHeader.ReadFrom(JSText);
        UpdateSalesHeaderFromShipStation(DocNo, JSObjectHeader);
    end;

    procedure CreateJsonItemForWooComerse(ItemNo: Code[20]): JsonObject
    var
        _Item: Record Item;
        _ItemDescription: Record "Item Description";
        _jsonText: Text;
        _jsonObject: JsonObject;
        _SalesPrice: Decimal;
    begin
        if (ItemNo = '') or not _Item.Get(ItemNo) or not _Item."Web Item" or not _ItemDescription.Get(ItemNo) then exit(_jsonObject);

        _jsonObject.Add('SKU', _Item."No.");
        _jsonObject.Add('name', jsonGetName(_Item."No."));
        _jsonObject.Add('price_regular', _Item."Unit Price");
        _SalesPrice := Round(_GetItemPrice(_Item."No."), 0.01, '>');
        if _SalesPrice < _Item."Unit Price" then begin
            _jsonObject.Add('price_sale', _SalesPrice);
            _jsonObject.Add('discount_value', _SalesPrice * 100 / _Item."Unit Price");
        end else begin
            _jsonObject.Add('price_sale', 0);
            _jsonObject.Add('discount_value', 0);
        end;
        _jsonObject.Add('available', jsonGetInventory(_Item."No."));
        _jsonObject.Add('category', jsonGetCategory(_Item."Item Category Code", 0));
        _jsonObject.Add('subcategory', jsonGetCategory(_Item."Item Category Code", 1));
        _jsonObject.Add('subsubcategory', jsonGetCategory(_Item."Item Category Code", 2));
        _jsonObject.Add('filters_group', jsonGetFilterGroupArray(_Item."No."));
        _jsonObject.Add('release_form', _Item."Item Form");
        _jsonObject.Add('brand', jsonGetBrand(_Item."Brand Code", _Item."Manufacturer Code"));
        _jsonObject.Add('manufacturer', jsonGetManufacturer(_Item."Manufacturer Code"));
        _jsonObject.Add('description', jsonGetBlobFromItemDescription(_Item."No.", _ItemDescription.FieldNo(Description), _ItemDescription.FieldNo("Description RU")));
        _jsonObject.Add('indication', jsonGetBlobFromItemDescription(_Item."No.", _ItemDescription.FieldNo(Indications), _ItemDescription.FieldNo("Indications RU")));
        _jsonObject.Add('ingredients', jsonGetBlobFromItemDescription(_Item."No.", _ItemDescription.FieldNo(Ingredients), _ItemDescription.FieldNo("Ingredients RU")));
        _jsonObject.Add('warning', jsonGetBlobFromItemDescription(_Item."No.", _ItemDescription.FieldNo(Warning), 0));
        _jsonObject.Add('legal_disclaimer', jsonGetBlobFromItemDescription(_Item."No.", _ItemDescription.FieldNo("Legal Disclaimer"), 0));
        _jsonObject.Add('directions', jsonGetBlobFromItemDescription(_Item."No.", _ItemDescription.FieldNo(Directions), _ItemDescription.FieldNo("Directions RU")));
        _jsonObject.Add('bullet_points', jsonGetBulletPoints(_Item."No."));
        _jsonObject.Add('images', jsonGetImages(_Item."No."));
        _jsonObject.Add('delivery', false); // TO DO
        if _ItemDescription."Sell-out" = 0D then
            _jsonObject.Add('is_sale', false)
        else
            _jsonObject.Add('is_sale', Today <= _ItemDescription."Sell-out");
        if _ItemDescription.New = 0D then
            _jsonObject.Add('is_new', false)
        else
            _jsonObject.Add('is_new', Today <= _ItemDescription.New);


        _jsonObject.WriteTo(_jsonText);
        // Message(_jsonText);
        exit(_jsonObject);
    end;

    local procedure jsonGetImages(_ItemNo: Code[20]): JsonArray
    var
        _ItemDescription: Record "Item Description";
        _jsonArray: JsonArray;
    begin
        if not _ItemDescription.Get(_ItemNo) then exit(_jsonArray);

        if _ItemDescription."Main Image URL" <> '' then
            _jsonArray.Add(_ItemDescription."Main Image URL");
        if _ItemDescription."Other Image URL" <> '' then
            _jsonArray.Add(_ItemDescription."Other Image URL");
        if _ItemDescription."Label Image URL" <> '' then
            _jsonArray.Add(_ItemDescription."Label Image URL");
        if _ItemDescription."Label Image URL 2" <> '' then
            _jsonArray.Add(_ItemDescription."Label Image URL 2");

        exit(_jsonArray);
    end;

    local procedure jsonGetBulletPoints(_ItemNo: Code[20]): JsonObject
    var
        _ItemDescription: Record "Item Description";
        _jsonObject: JsonObject;
        _jsonArray: JsonArray;
        _txtDescription: Text;
    begin
        if not _ItemDescription.Get(_ItemNo) then exit(_jsonObject);

        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 1"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 2"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 3"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 4"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _jsonArray.Add(_ItemDescription."Bullet Point 5");
        _jsonObject.Add('eng', _jsonArray);

        Clear(_jsonArray);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 1 RU"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 2 RU"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 3 RU"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _ItemDescription.BlobOnAfterGetRec(_ItemDescription.FieldNo("Bullet Point 4 RU"), _txtDescription);
        _jsonArray.Add(_txtDescription);
        _jsonArray.Add(_ItemDescription."Bullet Point 5 RU");
        _jsonObject.Add('ru', _jsonArray);

        exit(_jsonObject);
    end;

    local procedure jsonGetBlobFromItemDescription(_ItemNo: Code[20]; engFiledNo: Integer; ruFiledNo: Integer): JsonObject
    var
        _ItemDescription: Record "Item Description";
        _jsonObject: JsonObject;
        _txtDescription: Text;
    begin
        if not _ItemDescription.Get(_ItemNo) then exit(_jsonObject);

        if engFiledNo <> 0 then
            _ItemDescription.BlobOnAfterGetRec(engFiledNo, _txtDescription);
        _jsonObject.Add('eng', _txtDescription);

        Clear(_txtDescription);
        if ruFiledNo <> 0 then
            _ItemDescription.BlobOnAfterGetRec(ruFiledNo, _txtDescription);
        _jsonObject.Add('ru', _txtDescription);

        exit(_jsonObject)
    end;

    local procedure jsonGetManufacturer(_ManufacturerCode: Code[10]): JsonObject
    var
        _Manufacturer: Record Manufacturer;
        _jsonObject: JsonObject;
    begin
        if not _Manufacturer.Get(_ManufacturerCode) then exit(_jsonObject);

        _jsonObject.Add('id', _Manufacturer.Code);
        _jsonObject.Add('name', _Manufacturer.Name);

        exit(_jsonObject)
    end;

    local procedure jsonGetBrand(_BrandCode: Code[20]; _ManufacturerCode: Code[10]): JsonObject
    var
        _Brand: Record Brand;
        _jsonObject: JsonObject;
    begin
        if not _Brand.Get(_BrandCode, _ManufacturerCode) then exit(_jsonObject);

        _jsonObject.Add('id', _Brand.Code);
        _jsonObject.Add('name', _Brand.Name);

        exit(_jsonObject)
    end;

    local procedure jsonGetFilterGroupArray(_ItemNo: Code[20]): JsonArray
    var
        _ItemFilterGroup: Record "Item Filter Group";
        _oldItemFilterGroup: Text[50];
        _jsonItemFilterGroupArray: JsonArray;
        _jsonItemFilterGroup: JsonObject;
        _jsonItemFilters: JsonArray;
    begin
        with _ItemFilterGroup do begin
            SetRange("Item No.", _ItemNo);
            if FindSet(false, false) then
                repeat
                    if _oldItemFilterGroup <> "Filter Group" then begin
                        _jsonItemFilterGroup.Add('name', "Filter Group");
                        _jsonItemFilterGroup.Add('filters', AddItemFilterGroupArray("Item No.", "Filter Group"));
                        _jsonItemFilterGroupArray.Add(_jsonItemFilterGroup);
                        _jsonItemFilters.Add(_jsonItemFilterGroup);
                        Clear(_jsonItemFilterGroup);
                        _oldItemFilterGroup := "Filter Group";
                    end;
                until Next() = 0;
        end;
        exit(_jsonItemFilters);
    end;

    local procedure AddItemFilterGroupArray(_ItemNo: Code[20]; _FilterGroup: Text[50]): JsonArray
    var
        _ItemFilterGroup: Record "Item Filter Group";
        _jsonItemFilterGroupArray: JsonArray;
    begin
        with _ItemFilterGroup do begin
            SetRange("Item No.", _ItemNo);
            SetRange("Filter Group", _FilterGroup);
            if FindSet(false, false) then
                repeat
                    _jsonItemFilterGroupArray.Add("Filter Value");
                until Next() = 0;
        end;
        exit(_jsonItemFilterGroupArray);
    end;

    local procedure jsonGetCategory(_ItemCategoryCode: Code[20]; _Level: Integer): JsonObject
    var
        _ItemCategory: Record "Item Category";
        _jsonObject: JsonObject;
        _ParentCategory: Code[20];
    begin
        if not _ItemCategory.Get(_ItemCategoryCode) or (_ItemCategoryCode = '') then exit(_jsonObject);

        with _ItemCategory do begin
            if Indentation = _Level then begin
                _jsonObject.Add('id', Description);
                _jsonObject.Add('eng', Description);
                exit(_jsonObject);
            end;
            if "Parent Category" <> '' then
                exit(jsonGetCategory("Parent Category", _Level));
        end;
        exit(_jsonObject);
    end;

    local procedure jsonGetInventory(_ItemNo: Code[20]): JsonObject
    var
        _ItemDescr: Record "Item Description";
        _Item: Record Item;
        _jsonObject: JsonObject;
        engNotInventory: Label 'Not Inventory';
        engInventory: Label 'Inventory';
        ruNotInventory: Label 'Нет в наличии';
        ruInventory: Label 'В наличии';
    begin
        if not _Item.Get(_ItemNo) then exit(_jsonObject);
        _Item.CalcFields(Inventory);
        case _Item.Inventory of
            0:
                begin
                    _jsonObject.Add('eng', engNotInventory);
                    _jsonObject.Add('ru', ruNotInventory);
                end;
            else begin
                    _jsonObject.Add('eng', engInventory);
                    _jsonObject.Add('ru', ruInventory);
                end;
        end;
        exit(_jsonObject)
    end;

    local procedure _GetItemPrice(_ItemNo: Code[20]): Decimal
    var
        _Item: Record Item;
        _SalesPrice: Record "Sales Price";
    begin
        if not _Item.Get(_ItemNo) then exit(0);

        with _SalesPrice do begin
            SetCurrentKey("Item No.", "Sales Type", "Ending Date", "Unit Price");
            SetRange("Item No.", _Item."No.");
            SetRange("Sales Type", "Sales Type"::"All Customers");
            SetFilter("Ending Date", '%1..', Today);
            if FindFirst() then
                exit("Unit Price")
            else begin
                SetRange("Ending Date");
                if FindFirst() then
                    exit("Unit Price");
            end;
        end;

        exit(_Item."Unit Price");
    end;

    local procedure jsonGetName(_ItemNo: Code[20]): JsonObject
    var
        _ItemDescr: Record "Item Description";
        _Item: Record Item;
        _jsonObject: JsonObject;
    begin
        if not _Item.Get(_ItemNo) or not _ItemDescr.Get(_ItemNo) then exit(_jsonObject);

        _jsonObject.Add('eng', _Item.Description + _Item."Description 2");
        _jsonObject.Add('ru', _ItemDescr."Name RU" + _ItemDescr."Name RU 2");

        exit(_jsonObject)
    end;

    local procedure GetCarrierCodeByAgentCode(ShippingAgentCode: Code[10]): Text[50]
    var
        _SA: Record "Shipping Agent";
        _jsonNull: JsonObject;
    begin
        if _SA.Get(ShippingAgentCode) then
            exit(_SA."SS Code")
        else
            exit('');
    end;

    local procedure GetServiceCodeByAgentServiceCode(ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]): Text[50]
    var
        _SAS: Record "Shipping Agent Services";
        _jsonNull: JsonObject;
    begin
        if _SAS.Get(ShippingAgentCode, ShippingAgentServiceCode) then
            exit(_SAS."SS Code")
        else
            exit('');
    end;

    procedure UpdateSalesHeaderFromShipStation(DocNo: Code[20]; _jsonObject: JsonObject): Boolean
    var
        _SH: Record "Sales Header";
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
        _jsonToken: JsonToken;
    begin
        if not _SH.Get(_SH."Document Type"::Order, DocNo) then exit(false);
        // update Sales Header from ShipStation

        _jsonToken := GetJSToken(_jsonObject, 'carrierCode');
        if not _jsonToken.AsValue().IsNull then begin
            txtCarrierCode := CopyStr(GetJSToken(_jsonObject, 'carrierCode').AsValue().AsText(), 1, MaxStrLen(txtCarrierCode));
            _SH.Validate("Shipping Agent Code", GetShippingAgent(txtCarrierCode));

            _jsonToken := GetJSToken(_jsonObject, 'serviceCode');
            if not _jsonToken.AsValue().IsNull then begin
                txtServiceCode := CopyStr(GetJSToken(_jsonObject, 'serviceCode').AsValue().AsText(), 1, MaxStrLen(txtServiceCode));
                _SH.Validate("Shipping Agent Service Code", GetShippingAgentService(txtServiceCode, txtCarrierCode));
            end;
        end;

        _SH."ShipStation Order ID" := GetJSToken(_jsonObject, 'orderId').AsValue().AsText();
        _SH."ShipStation Order Key" := GetJSToken(_jsonObject, 'orderKey').AsValue().AsText();
        _SH."ShipStation Status" := CopyStr(GetJSToken(_jsonObject, 'orderStatus').AsValue().AsText(), 1, MaxStrLen(_SH."ShipStation Status"));
        _SH."ShipStation Shipment Amount" := GetJSToken(_jsonObject, 'shippingAmount').AsValue().AsDecimal();

        case _SH."ShipStation Order Status" of
            _SH."ShipStation Order Status"::"Not Sent":
                _SH."ShipStation Order Status" := _SH."ShipStation Order Status"::Sent;
            _SH."ShipStation Order Status"::Sent:
                _SH."ShipStation Order Status" := _SH."ShipStation Order Status"::Updated;
        end;



        if _SH."ShipStation Status" = lblAwaitingShipment then begin
            _SH."Package Tracking No." := '';
            _SH."ShipStation Shipment ID" := '';
        end;
        _SH.Modify();
    end;

    procedure CreateLabel2OrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        JSText: Text;
        JSObject: JsonObject;
        jsLabelObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        notExistOrdersList: Text;
        OrdersListCreateLabel: Text;
        OrdersCancelled: Text;
        txtLabel: Text;
        txtBeforeName: Text;
        WhseShipDocNo: Code[20];
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) or (_SH."ShipStation Order ID" = '') then exit(false);
        // if not FindWarehouseSipment(DocNo, WhseShipDocNo) then exit(false); // comment to test Create Label and Attache to Warehouse Shipment

        // Get Order from Shipstation to Fill Variables
        JSText := Connect2ShipStation(1, '', StrSubstNo('/%1', _SH."ShipStation Order ID"));

        JSObject.ReadFrom(JSText);
        JSText := Connect2ShipStation(3, FillValuesFromOrder(JSObject), '');

        // Update Order From Label
        UpdateOrderFromLabel(DocNo, JSText);

        WhseShipDocNo := '111'; // code to test attache

        // Add Lable to Shipment
        jsLabelObject.ReadFrom(JSText);
        txtLabel := GetJSToken(jsLabelObject, 'labelData').AsValue().AsText();
        txtBeforeName := _SH."No." + '-' + GetJSToken(jsLabelObject, 'trackingNumber').AsValue().AsText();

        SaveLabel2Shipment(txtBeforeName, txtLabel, WhseShipDocNo);

        // Update Sales Header From ShipStation
        JSText := Connect2ShipStation(1, '', StrSubstNo('/%1', _SH."ShipStation Order ID"));
        JSObject.ReadFrom(JSText);
        UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);

        Message('Label Created and Attached to Warehouse Shipment %1', WhseShipDocNo);
    end;

    procedure VoidLabel2OrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        JSText: Text;
        JSObject: JsonObject;
        WhseShipDocNo: Code[20];
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) or (_SH."ShipStation Shipment ID" = '') then exit(false);

        // Void Label in Shipstation
        JSObject.Add('shipmentId', _SH."ShipStation Shipment ID");
        JSObject.WriteTo(JSText);
        JSText := Connect2ShipStation(8, JSText, '');
        JSObject.ReadFrom(JSText);

        Message(GetJSToken(JSObject, 'message').AsValue().AsText(), '%1', WhseShipDocNo);

        // Update Sales Header From ShipStation
        JSText := Connect2ShipStation(1, '', StrSubstNo('/%1', _SH."ShipStation Order ID"));
        JSObject.ReadFrom(JSText);
        UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);
    end;

    local procedure UpdateOrderFromLabel(DocNo: Code[20]; jsonText: Text);
    var
        _SH: Record "Sales Header";
        jsLabelObject: JsonObject;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        jsLabelObject.ReadFrom(jsonText);
        _SH."ShipStation Insurance Cost" := GetJSToken(jsLabelObject, 'insuranceCost').AsValue().AsDecimal();
        _SH."ShipStation Shipment Cost" := GetJSToken(jsLabelObject, 'shipmentCost').AsValue().AsDecimal();
        _SH."Package Tracking No." := GetJSToken(jsLabelObject, 'trackingNumber').AsValue().AsText();
        _SH."ShipStation Shipment ID" := GetJSToken(jsLabelObject, 'shipmentId').AsValue().AsText();
        _SH.Modify();
    end;

    local procedure FindWarehouseSipment(_DocNo: Code[20]; var _WhseShipDcoNo: Code[20]): Boolean
    var
        WhseShipLine: Record "Warehouse Shipment Line";
    begin
        with WhseShipLine do begin
            SetCurrentKey("Source Type", "Source Subtype", "Source No.");
            SetRange("Source Type", Database::"Sales Header");
            SetRange("Source Subtype", 1);
            SetRange("Source No.", _DocNo);
            if FindFirst() then begin
                _WhseShipDcoNo := "No.";
                exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure SaveLabel2Shipment(_txtBefore: Text; _txtLabelBase64: Text; _WhseShipDocNo: Code[20])
    var
        Base64Convert: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        WhseShipHeader: Record "Warehouse Shipment Header";
        lblOrder: TextConst ENU = 'SalesOrder', RUS = 'SalesOrder';
        DocumentAttachment: Record "Document Attachment";
        FileName: Text;
        LabelToPDF: Text;
    begin
        RecRef.OPEN(DATABASE::"Warehouse Shipment Header");
        WhseShipHeader.Get(_WhseShipDocNo);
        RecRef.GETTABLE(WhseShipHeader);
        LabelToPDF := Base64Convert.FromBase64(_txtLabelBase64);
        FileName := StrSubstNo('%1-%2.pdf', _txtBefore, lblOrder);
        SaveAttachment2WhseShmt(RecRef, FileName, LabelToPDF);
    end;

    local procedure SaveAttachment2WhseShmt(RecRef: RecordRef; FileName: Text; LabelToPDF: Text)
    var
        FieldRef: FieldRef;
        _InStream: InStream;
        _OutStream: OutStream;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        LineNo: Integer;
        TempBlob: Codeunit "Temp Blob";
        DocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        IncomingFileName: Text;
    begin
        with DocumentAttachment do begin
            IncomingFileName := FileName;
            Init();
            Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
            Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));

            TempBlob.CreateOutStream(_OutStream);
            _OutStream.WriteText(LabelToPDF);
            TempBlob.CreateInStream(_InStream);
            "Document Reference ID".ImportStream(_InStream, IncomingFileName);

            Validate("Table ID", RecRef.Number);
            FieldRef := RecRef.Field(1);
            RecNo := FieldRef.Value;
            Validate("No.", RecNo);
            Insert(true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, 1174, 'OnBeforeDrillDown', '', true, true)]
    local procedure BeforeDrillDownSetFilters(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        WSHeader: Record "Warehouse Shipment Header";
    begin
        with DocumentAttachment do begin
            RecRef.OPEN(DATABASE::"Warehouse Shipment Header");
            IF WSHeader.GET("No.") THEN
                RecRef.GETTABLE(WSHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Page, 1173, 'OnAfterOpenForRecRef', '', true, true)]
    local procedure AfterOpenForRecRefSetFilters(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        with DocumentAttachment do
            CASE RecRef.NUMBER OF
                DATABASE::"Warehouse Shipment Header":
                    BEGIN
                        SetRange("Table ID", Database::"Warehouse Shipment Header");
                        FieldRef := RecRef.FIELD(1);
                        RecNo := FieldRef.VALUE;
                        SETRANGE("No.", RecNo);
                    END;
            END;
    end;

    local procedure CreateListAsFilter(var _List: Text; _subString: Text)
    begin
        if _List = '' then
            _List += _subString
        else
            _List += '|' + _subString;
    end;

    local procedure FillValuesFromOrder(_JSObject: JsonObject): Text
    var
        JSObjectHeader: JsonObject;
        JSText: Text;
        jsonNull: JsonObject;
        jsonInsurance: JsonObject;
    begin
        if GetJSToken(_JSObject, 'carrierCode').AsValue().IsNull then
            exit(StrSubstNo(errCarrierIsNull, GetJSToken(_JSObject, 'orderNumber').AsValue().AsText()));
        if GetJSToken(_JSObject, 'serviceCode').AsValue().IsNull then
            exit(StrSubstNo(errServiceIsNull, GetJSToken(_JSObject, 'orderNumber').AsValue().AsText()));

        JSObjectHeader.Add('orderId', GetJSToken(_JSObject, 'orderId').AsValue().AsInteger());
        JSObjectHeader.Add('carrierCode', GetJSToken(_JSObject, 'carrierCode').AsValue().AsText());
        JSObjectHeader.Add('serviceCode', GetJSToken(_JSObject, 'serviceCode').AsValue().AsText());
        JSObjectHeader.Add('packageCode', GetJSToken(_JSObject, 'packageCode').AsValue().AsText());
        JSObjectHeader.Add('confirmation', GetJSToken(_JSObject, 'confirmation').AsValue().AsText());
        JSObjectHeader.Add('shipDate', Date2Text4SS(Today));
        JSObjectHeader.Add('weight', GetJSToken(_JSObject, 'weight').AsObject());

        if not GetJSToken(_JSObject, 'dimensions').isValue() then
            JSObjectHeader.Add('dimensions', GetJSToken(_JSObject, 'dimensions').AsObject());

        if not GetJSToken(_JSObject, 'insuranceOptions').IsValue then begin
            jsonInsurance := GetJSToken(_JSObject, 'insuranceOptions').AsObject();
            if GetJSToken(jsonInsurance, 'insureShipment').AsValue().AsBoolean() then
                JSObjectHeader.Add('insuranceOptions', GetJSToken(_JSObject, 'insuranceOptions').AsObject());
        end;

        if not GetJSToken(_JSObject, 'internationalOptions').IsValue then
            JSObjectHeader.Add('internationalOptions', GetJSToken(_JSObject, 'internationalOptions').AsObject());

        if not GetJSToken(_JSObject, 'advancedOptions').IsValue then
            JSObjectHeader.Add('advancedOptions', GetJSToken(_JSObject, 'advancedOptions').AsObject());

        JSObjectHeader.Add('testLabel', false);
        JSObjectHeader.WriteTo(JSText);
        exit(JSText);
    end;

    procedure jsonBillToFromSH(DocNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtBillTo: Text;
        _SH: Record "Sales Header";
        _Cust: Record Customer;
        _Contact: Record Contact;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        _Cust.Get(_SH."Bill-to Customer No.");
        _Contact.Get(_SH."Bill-to Contact No.");

        JSObjectLine.Add('name', _SH."Bill-to Contact");
        JSObjectLine.Add('company', _Cust.Name);
        JSObjectLine.Add('street1', _SH."Bill-to Address");
        JSObjectLine.Add('street2', _SH."Bill-to Address 2");
        JSObjectLine.Add('street3', '');
        JSObjectLine.Add('city', _SH."Bill-to City");
        JSObjectLine.Add('state', _SH."Bill-to County");
        JSObjectLine.Add('postalCode', _SH."Bill-to Post Code");
        JSObjectLine.Add('country', _SH."Bill-to Country/Region Code");
        JSObjectLine.Add('phone', _Contact."Phone No.");
        JSObjectLine.Add('residential', false);
        exit(JSObjectLine);
    end;

    procedure jsonShipToFromSH(DocNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtShipTo: Text;
        _SH: Record "Sales Header";
        _Cust: Record Customer;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        _Cust.Get(_SH."Sell-to Customer No.");

        JSObjectLine.Add('name', _SH."Sell-to Contact");
        JSObjectLine.Add('company', _SH."Sell-to Customer Name");
        JSObjectLine.Add('street1', _SH."Sell-to Address");
        JSObjectLine.Add('street2', _SH."Sell-to Address 2");
        JSObjectLine.Add('street3', '');
        JSObjectLine.Add('city', _SH."Sell-to City");
        JSObjectLine.Add('state', _SH."Sell-to County");
        JSObjectLine.Add('postalCode', _SH."Sell-to Post Code");
        JSObjectLine.Add('country', _SH."Ship-to Country/Region Code");
        JSObjectLine.Add('phone', _SH."Sell-to Phone No.");
        JSObjectLine.Add('residential', false);
        exit(JSObjectLine);
    end;

    procedure jsonItemsFromSL(DocNo: Code[20]): JsonArray
    var
        JSObjectLine: JsonObject;
        JSObjectArray: JsonArray;
        _SL: Record "Sales Line";
        _ID: Record "Item Description";
    begin
        _SL.SetCurrentKey(Type, Quantity);
        _SL.SetRange("Document Type", _SL."Document Type"::Order);
        _SL.SetRange("Document No.", DocNo);
        _SL.SetRange(Type, _SL.Type::Item);
        _SL.SetFilter(Quantity, '<>%1', 0);
        if _SL.FindSet(false, false) then
            repeat
                Clear(JSObjectLine);

                JSObjectLine.Add('lineItemKey', _SL."Line No.");
                JSObjectLine.Add('sku', _SL."No.");
                JSObjectLine.Add('name', _SL.Description);
                if _ID.Get(_SL."No.") then
                    JSObjectLine.Add('imageUrl', _ID."Main Image URL");
                JSObjectLine.Add('weight', jsonWeightFromItem(_SL."Gross Weight"));
                JSObjectLine.Add('quantity', Decimal2Integer(_SL.Quantity));
                JSObjectLine.Add('unitPrice', Round(_SL."Amount Including VAT" / _SL.Quantity, 0.01));
                JSObjectLine.Add('taxAmount', Round((_SL."Amount Including VAT" - _SL.Amount) / _SL.Quantity, 0.01));
                // JSObjectLine.Add('shippingAmount', 0);
                JSObjectLine.Add('warehouseLocation', _SL."Location Code");
                JSObjectLine.Add('productId', _SL."Line No.");
                JSObjectLine.Add('fulfillmentSku', '');
                JSObjectLine.Add('adjustment', false);
                JSObjectArray.Add(JSObjectLine);
            until _SL.Next() = 0;
        exit(JSObjectArray);
    end;

    local procedure Decimal2Integer(_Decimal: Decimal): Integer
    begin
        exit(Round(_Decimal, 1));
    end;

    procedure jsonWeightFromItem(_GrossWeight: Decimal): JsonObject
    var
        JSObjectLine: JsonObject;
    begin
        JSObjectLine.Add('value', _GrossWeight + 1000);
        JSObjectLine.Add('units', 'ounces'); // Lena confirmed
        exit(JSObjectLine);
    end;

    procedure jsonDimentionsFromAttributeValue(_No: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        lblInc: Label 'inches';
        lblCm: Label 'centimeters';
        txtUnits: Text;
        decDimension: Decimal;
    begin
        if Evaluate(decDimension, GetItemAttributeValue(Database::"Sales Header", _No, 'length', txtUnits)) then
            JSObjectLine.Add('length', decDimension);
        if Evaluate(decDimension, GetItemAttributeValue(Database::"Sales Header", _No, 'width', txtUnits)) then
            JSObjectLine.Add('width', decDimension);
        if Evaluate(decDimension, GetItemAttributeValue(Database::"Sales Header", _No, 'height', txtUnits)) then
            JSObjectLine.Add('height', decDimension);

        if txtUnits in [lblCm, lblInc] then
            JSObjectLine.Add('units', txtUnits)
        else
            JSObjectLine.Add('units', lblCm);
        exit(JSObjectLine);
    end;

    local procedure GetItemAttributeValue(TableID: Integer; ItemNo: Code[20]; TokenKey: Text; var _Units: Text): Text
    var
        _ItemAttr: Record "Item Attribute";
        _ItemAttrValue: Record "Item Attribute Value";
        _ItemAttrValueMapping: Record "Item Attribute Value Mapping";
        _UoM: Record "Unit of Measure";
    begin
        _ItemAttr.SetCurrentKey(Name);
        _ItemAttr.SetRange(Name, TokenKey);
        if _ItemAttr.FindFirst() then begin
            _Units := LowerCase(_ItemAttr."Unit of Measure");
            if _ItemAttrValueMapping.Get(TableID, ItemNo, _ItemAttr.ID) then begin
                _ItemAttrValue.Get(_ItemAttrValueMapping."Item Attribute ID", _ItemAttrValueMapping."Item Attribute Value ID");
                exit(_ItemAttrValue.Value);
            end;
        end;
        exit('');
    end;

    procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure SelectJSToken(_JSONObject: JsonObject; Path: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.SelectToken(Path, _JSONToken) then
            Error('Could not find a token with path %1', Path);
    end;

    local procedure Date2Text4SS(_Date: Date): Text
    var
        _Year: Text[4];
        _Month: Text[2];
        _Day: Text[2];
    begin
        EVALUATE(_Day, Format(Date2DMY(_Date, 1)));
        AddZero2String(_Day, 2);
        EVALUATE(_Month, Format(Date2DMY(_Date, 2)));
        AddZero2String(_Month, 2);
        EVALUATE(_Year, Format(Date2DMY(_Date, 3)));
        EXIT(_Year + '-' + _Month + '-' + _Day);
    end;

    local procedure GetDateFromJsonText(_DateText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        EVALUATE(Year, COPYSTR(_DateText, 1, 4));
        EVALUATE(Month, COPYSTR(_DateText, 6, 2));
        EVALUATE(Day, COPYSTR(_DateText, 9, 2));
        EXIT(DMY2DATE(Day, Month, Year));
    end;

    local procedure Date2Text4JSON(_Date: Date): Text
    var
        _Year: Text[4];
        _Month: Text[2];
        _Day: Text[2];
    begin
        EVALUATE(_Day, Format(Date2DMY(_Date, 1)));
        AddZero2String(_Day, 2);
        EVALUATE(_Month, Format(Date2DMY(_Date, 2)));
        AddZero2String(_Month, 2);
        EVALUATE(_Year, Format(Date2DMY(_Date, 3)));
        EXIT(_Year + '-' + _Month + '-' + _Day + 'T00:00:00.0000000');
    end;

    local procedure AddZero2String(var _String: Text; _maxLenght: Integer)
    begin
        while _maxLenght > StrLen(_String) do
            _String := StrSubstNo('%1%2', '0', _String);
    end;

    procedure GetCarrierFromShipStation(_SSAgentCode: Text[20]): Code[10]
    var
        JSText: Text;
        JSObject: JsonObject;
        CarrierToken: JsonToken;
        Counter: Integer;
        txtCarrierCode: Text[20];
        ShippingAgent: Record "Shipping Agent";
    begin
        JSText := Connect2ShipStation(6, '', _SSAgentCode);

        JSObject.ReadFrom(JSText);
        txtCarrierCode := CopyStr(GetJSToken(JSObject, 'code').AsValue().AsText(), 1, MaxStrLen(ShippingAgent."SS Code"));
        ShippingAgent.SetCurrentKey("SS Code");
        ShippingAgent.SetRange("SS Code", txtCarrierCode);
        if not ShippingAgent.FindFirst() then
            ShippingAgent.InsertCarrierFromShipStation(GetLastCarrierCode(), CopyStr(GetJSToken(JSObject, 'name').AsValue().AsText(), 1, MaxStrLen(ShippingAgent.Name)),
                                                       txtCarrierCode, GetJSToken(JSObject, 'shippingProviderId').AsValue().AsInteger());
        ShippingAgent.FindFirst();
        exit(ShippingAgent.Code);
    end;

    procedure GetCarriersFromShipStation(): Boolean
    var
        _SA: Record "Shipping Agent";
        JSText: Text;
        JSObject: JsonObject;
        CarriersJSArray: JsonArray;
        CarrierToken: JsonToken;
        Counter: Integer;
        txtCarrierCode: Text[20];
    begin
        JSText := Connect2ShipStation(4, '', '');

        CarriersJSArray.ReadFrom(JSText);
        foreach CarrierToken in CarriersJSArray do begin
            txtCarrierCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'code').AsValue().AsText(), 1, MaxStrLen(_SA."SS Code"));
            _SA.SetCurrentKey("SS Code");
            _SA.SetRange("SS Code", txtCarrierCode);
            if not _SA.FindFirst() then
                _SA.InsertCarrierFromShipStation(GetLastCarrierCode(), CopyStr(GetJSToken(CarrierToken.AsObject(), 'name').AsValue().AsText(), 1, MaxStrLen(_SA.Name)),
                                                           txtCarrierCode, GetJSToken(CarrierToken.AsObject(), 'shippingProviderId').AsValue().AsInteger());
        end;
        exit(true);
    end;

    local procedure GetLastCarrierCode(): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
        lblSA_Code: Label 'SA-0001';
        lblSA_CodeFilter: Label 'SA-*';
    begin
        ShippingAgent.SetFilter(Code, '%1', lblSA_CodeFilter);
        if ShippingAgent.FindLast() then exit(IncStr(ShippingAgent.Code));
        exit(lblSA_Code);
    end;

    local procedure TempGetLastCarrierCode(var ShippingAgent: Record "Shipping Agent" temporary): Code[10]
    var
        lblSA_Code: Label 'SA-0001';
        lblSA_CodeFilter: Label 'SA-*';
    begin
        ShippingAgent.Reset();
        ShippingAgent.SetFilter(Code, '%1', lblSA_CodeFilter);
        if ShippingAgent.FindLast() then exit(IncStr(ShippingAgent.Code));
        exit(lblSA_Code);
    end;

    procedure GetServicesFromShipStation(_SSAgentCode: Text[20]): Boolean
    var
        JSText: Text;
        JSObject: JsonObject;
        CarriersJSArray: JsonArray;
        CarrierToken: JsonToken;
        Counter: Integer;
        ShippingAgentServices: Record "Shipping Agent Services";
        _SSCode: Text[50];
    begin
        JSText := Connect2ShipStation(5, '', _SSAgentCode);

        CarriersJSArray.ReadFrom(JSText);
        foreach CarrierToken in CarriersJSArray do begin
            _SSAgentCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'carrierCode').AsValue().AsText(), 1, MaxStrLen(ShippingAgentServices."SS Carrier Code"));
            _SSCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'code').AsValue().AsText(), 1, MaxStrLen(ShippingAgentServices."SS Code"));
            with ShippingAgentServices do begin
                SetCurrentKey("SS Carrier Code", "SS Code");
                SetRange("SS Carrier Code", _SSAgentCode);
                SetRange("SS Code", _SSCode);
                if FindFirst() then exit(true);
                InsertServicesFromShipStation(GetCarrierCodeBySSAgentCode(_SSAgentCode), GetLastCarrierServiceCode(), _SSAgentCode, _SSCode,
                                              CopyStr(GetJSToken(CarrierToken.AsObject(), 'name').AsValue().AsText(), 1, MaxStrLen(ShippingAgentServices.Description)));
            end;
        end;
        exit(true);
    end;

    local procedure GetCarrierCodeBySSAgentCode(_SSAgentCode: Text[20]): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        with ShippingAgent do begin
            SetCurrentKey("SS Code");
            SetRange("SS Code", _SSAgentCode);
            FindFirst();
            exit(Code);
        end;
    end;

    local procedure GetLastCarrierServiceCode(): Code[10]
    var
        _SAS: Record "Shipping Agent Services";
        lblSASCode: Label 'SAS-0001';
        lblSASCodeFilter: Label 'SAS-*';
    begin
        _SAS.SetFilter(Code, '%1', lblSASCodeFilter);
        if _SAS.FindLast() then exit(IncStr(_SAS.Code));
        exit(lblSASCode);
    end;

    procedure GetShippingRatesByCarrier(_SH: Record "Sales Header")
    var
        TotalGrossWeight: Decimal;
    begin
        TotalGrossWeight := GetOrderGrossWeight(_SH);
        if not (TotalGrossWeight > 0) then Error(StrSubstNo(errTotalGrossWeightIsZero, TotalGrossWeight));
        // Update Carriers And Services
        // UpdateCarriersAndServices(_SA, _SAS);

        UpdateCarriersAndServices();
        // Init Shipping Amount
        InitShippingAmount();
        // Get Rates By Carrier From ShipStation
        // GetRatesByCarrierFromShipStation(_SH, _SA, _SAS);
        GetRatesByCarrierFromShipStation(_SH);
    end;

    procedure GetOrderGrossWeight(SalesHeader: Record "Sales Header"): Decimal
    var
        _SL: Record "Sales Line";
        TotalGrossWeight: Decimal;
    begin
        TotalGrossWeight := 0;
        with _SL do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            if FindSet(false, false) then
                repeat
                    TotalGrossWeight += Quantity * "Gross Weight";
                until Next() = 0;
        end;
        exit(TotalGrossWeight);
    end;

    procedure UpdateCarriersAndServices()
    var
        _SA: Record "Shipping Agent";
    begin
        // GetCarriersFromShipStation(_SA, _SAS);
        if Confirm(confUpdateCarriersList, false, _SA.TableCaption) then
            GetCarriersFromShipStation();
    end;

    procedure InitShippingAmount()
    var
        _SAS: Record "Shipping Agent Services";
    begin
        with _SAS do begin
            ModifyAll("Shipment Cost", 0);
            ModifyAll("Other Cost", 0);
        end;
    end;

    procedure GetRatesByCarrierFromShipStation(_SH: Record "Sales Header")
    var
        _SA: Record "Shipping Agent";
        jsText: Text;
        jsObject: JsonObject;
        jsRatesArray: JsonArray;
    begin
        _SA.SetCurrentKey("SS Code");
        _SA.SetFilter("SS Code", '<>%1', '');
        if _SA.FindSet() then
            repeat
                jsObject.Add('carrierCode', _SA."SS Code");
                jsObject.Add('fromPostalCode', GetFromPostalCode(_SH."Location Code"));
                jsObject.Add('toCountry', _SH."Sell-to Country/Region Code");
                jsObject.Add('toPostalCode', _SH."Sell-to Post Code");
                jsObject.Add('weight', jsonWeightFromItem(GetOrderGrossWeight(_SH)));
                jsObject.WriteTo(jsText);

                JSText := Connect2ShipStation(7, jsText, '');
                jsRatesArray.ReadFrom(jsText);

                // update Shipping Cost into Shipping Agent Service
                InsertServicesAndUpdateServiceCostsFromShipStation(_SA."SS Code", jsRatesArray);
                Clear(jsObject);
            until _SA.Next() = 0;
    end;

    procedure InsertServicesAndUpdateServiceCostsFromShipStation(CarrierCode: Text[20]; jsonRatesArray: JsonArray)
    var
        _SAS: Record "Shipping Agent Services";
        CarrierToken: JsonToken;
        ServiceCode: Text[100];
    begin
        foreach CarrierToken in jsonRatesArray do begin
            ServiceCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'serviceCode').AsValue().AsText(), 1, MaxStrLen(_SAS."SS Code"));
            with _SAS do begin
                SetCurrentKey("SS Carrier Code", "SS Code");
                SetRange("SS Carrier Code", CarrierCode);
                SetRange("SS Code", ServiceCode);
                if not FindFirst() then
                    // Insert Services
                    InsertServicesFromShipStation(GetCarrierCodeBySSAgentCode(CarrierCode), GetLastCarrierServiceCode(), CarrierCode, ServiceCode,
                                              CopyStr(GetJSToken(CarrierToken.AsObject(), 'serviceName').AsValue().AsText(), 1, MaxStrLen(_SAS.Description)));
                "Shipment Cost" := GetJSToken(CarrierToken.AsObject(), 'shipmentCost').AsValue().AsDecimal();
                "Other Cost" := GetJSToken(CarrierToken.AsObject(), 'otherCost').AsValue().AsDecimal();
                Modify();
            end;
        end;
    end;

    procedure GetFromPostalCode(_LocationCode: Code[10]): Text
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.SetCurrentKey(Name);
        CompanyInfo.SetRange(Name, CompanyName);
        if CompanyInfo.FindFirst() then exit(CompanyInfo."Ship-to Post Code");
        if Location.Get(_LocationCode) then exit(Location."Post Code");
    end;

    var
        testMode: Boolean;
        errCarrierIsNull: TextConst ENU = 'Not Carrier Into ShipStation In Order = %1', RUS = 'В Заказе = %1 ShipStation не оппределен Перевозчик';
        errServiceIsNull: TextConst ENU = 'Not Service Into ShipStation In Order = %1', RUS = 'В Заказе = %1 ShipStation не оппределен Сервис';
        errTotalGrossWeightIsZero: TextConst ENU = 'Total Gross Weight Order = %1\But Must Be > 0', RUS = 'Общий Брутто вес Заказа = %1\Должен быть > 0';
        lblAwaitingShipment: Label 'awaiting_shipment';
        confUpdateCarriersList: TextConst ENU = 'Update the list %1?', RUS = 'Обновить список %1?';
        globalToken: Text;
}