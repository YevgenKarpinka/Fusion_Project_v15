pageextension 50009 "Item List Ext." extends "Item List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Type)
        {
            field("Expiration Inventory"; "Expiration Inventory")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addfirst(PeriodicActivities)
        {
            group(eCommerce)
            {
                CaptionML = ENU = 'eCommerce', RUS = 'eCommerce';
                Image = SuggestCustomerPayments;

                action(Send)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send', RUS = 'Отправить';
                    Image = ShowInventoryPeriods;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _jsonItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                    begin
                        CurrPage.SetSelectionFilter(_Item);

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                _jsonItem := ShipStationMgt.CreateJsonItemForWooComerse(_Item."No.");
                                _jsonItemList.Add(_jsonItem);

                                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));
                                Counter += 1;

                                if (Counter mod 50) = 0 then begin
                                    _jsonItemList.WriteTo(_jsonText);
                                    ShipStationMgt.AddProduct2eShop(_jsonText);
                                    Clear(_jsonItemList);
                                end;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        _jsonItemList.WriteTo(_jsonText);
                        ShipStationMgt.AddProduct2eShop(_jsonText);
                        // CaptionMgt.SaveStreamToFile(_jsonText);
                        // Message(_jsonText);
                    end;
                }
                action(SendAll)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send All', RUS = 'Отправить все';
                    Image = SuggestVendorPayments;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _jsonItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;

                    begin
                        // CurrPage.SetSelectionFilter(_Item);

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                _jsonItem := ShipStationMgt.CreateJsonItemForWooComerse(_Item."No.");
                                _jsonItemList.Add(_jsonItem);

                                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));
                                Counter += 1;

                                if (Counter mod 5) = 0 then begin
                                    _jsonItemList.WriteTo(_jsonText);
                                    ShipStationMgt.AddProduct2eShop(_jsonText);
                                    Clear(_jsonItemList);
                                end;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        _jsonItemList.WriteTo(_jsonText);
                        ShipStationMgt.AddProduct2eShop(_jsonText);
                        // CaptionMgt.SaveStreamToFile(_jsonText);
                        // Message(_jsonText);
                    end;
                }
                action(SendAll2File)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Send All to File', RUS = 'Отправить все в файл';
                    Image = SuggestVendorPayments;

                    trigger OnAction()
                    var
                        _Item: Record Item;
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _jsonItemList: JsonArray;
                        _jsonItem: JsonObject;
                        _jsonText: Text;
                        TotalCount: Integer;
                        Counter: Integer;
                    begin
                        // CurrPage.SetSelectionFilter(_Item);

                        Counter := 0;
                        TotalCount := _Item.Count;
                        ConfigProgressBarRecord.Init(TotalCount, Counter, STRSUBSTNO(ApplyingURLMsg, _Item.TableCaption));

                        if _Item.FindSet(false, false) then
                            repeat
                                _jsonItem := ShipStationMgt.CreateJsonItemForWooComerse(_Item."No.");
                                _jsonItemList.Add(_jsonItem);

                                ConfigProgressBarRecord.Update(STRSUBSTNO(RecordsXofYMsg, Counter, TotalCount));
                                Counter += 1;
                            until _Item.Next() = 0;
                        ConfigProgressBarRecord.Close;
                        _jsonItemList.WriteTo(_jsonText);
                        // ShipStationMgt.AddProduct2eShop(_jsonText);
                        CaptionMgt.SaveStreamToFile(_jsonText);
                        // Message(_jsonText);
                    end;
                }
            }
        }
    }
    var
        RecordsXofYMsg: TextConst ENU = 'Records: %1 of %2', RUS = 'Запись: %1 из %2';
        ApplyingURLMsg: TextConst ENU = 'Applying Table %1', RUS = 'Применяется таблица %1';
        ConfigProgressBarRecord: Codeunit "Config Progress Bar";
        CaptionMgt: Codeunit "Caption Mgt.";
}