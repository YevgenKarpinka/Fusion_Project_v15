table 50000 "Item Description"
{
    DataClassification = ToBeClassified;
    Caption = 'Item Description';

    fields
    {
        field(1; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item."No.";
        }
        field(2; Description; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(3; "Bullet Point 1"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(4; "Bullet Point 2"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(5; "Bullet Point 3"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(6; "Bullet Point 4"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(7; "Bullet Point 5"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(8; "Main Image URL"; Text[150])
        {
            DataClassification = ToBeClassified;
        }
        field(9; "Other Image URL"; Text[150])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Label Image URL"; Text[150])
        {
            DataClassification = ToBeClassified;
        }
        field(11; "Label Image URL 2"; Text[150])
        {
            DataClassification = ToBeClassified;
        }
        field(12; "Search Terms"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(13; "Search Terms for Google only"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(14; Ingredients; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(15; Indications; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(16; Directions; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(17; Warning; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(18; "Name RU"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(19; "Name RU 2"; Text[50])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Description RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(21; "Bullet Point 1 RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(22; "Bullet Point 2 RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(23; "Bullet Point 3 RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(24; "Bullet Point 4 RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(25; "Bullet Point 5 RU"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(26; "Ingredients RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(27; "Indications RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(28; "Directions RU"; Blob)
        {
            DataClassification = ToBeClassified;
            Subtype = Memo;
        }
        field(29; "New"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Sell-out"; Date)
        {
            DataClassification = ToBeClassified;
        }
        field(31; Barcode; Text[20])
        {
            DataClassification = ToBeClassified;
        }
    }
    keys
    {
        key(PK; "Item No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
    end;

    trigger OnModify()
    begin
    end;

    trigger OnDelete()
    begin
    end;

    trigger OnRename()
    begin
    end;

    procedure InitItemDescription(ItemNo: Code[20])
    begin
        Init();
        "Item No." := ItemNo;
        if not Insert() then Modify();
    end;

    // >>>
    procedure BlobOnAfterGetRec(_FieldNo: Integer; var _TextField: Text);
    var
        tmpTenantMedia: Record "Tenant Media" temporary;
        _FieldRef: FieldRef;
        _RecordRef: RecordRef;
        _InStream: InStream;
    begin
        _RecordRef.GetTable(Rec);
        _FieldRef := _RecordRef.Field(_FieldNo);
        _FieldRef.CalcField();
        tmpTenantMedia.Content := _FieldRef.Value;
        if not tmpTenantMedia.Content.HasValue then
            _TextField := ''
        else begin
            tmpTenantMedia.Content.CreateInStream(_InStream);
            _InStream.ReadText(_TextField);
        end;
    end;

    procedure BlobAssistEdit(_FieldNo: Integer; var _TextField: Text);
    var
        tmpTenantMedia: Record "Tenant Media" temporary;
        _FieldRef: FieldRef;
        _RecordRef: RecordRef;
        _InStream: InStream;
        _OutStream: OutStream;
        _ClientFileName: Text;
    begin
        _RecordRef.GetTable(Rec);
        _FieldRef := _RecordRef.Field(_FieldNo);
        _FieldRef.CalcField();
        tmpTenantMedia.Content := _FieldRef.Value;
        if tmpTenantMedia.Content.HasValue then
            if not Confirm(Text001) then
                Error('');
        if UploadIntoStream(Text002,
                            Text003,
                            Text004,
                            _ClientFileName,
                            _InStream) then
            Message(Text005)
        else
            exit;

        tmpTenantMedia.Content.CreateOutStream(_OutStream);
        CopyStream(_OutStream, _InStream);
        _FieldRef.Value := tmpTenantMedia.Content;
        _RecordRef.Modify;
        _InStream.ReadText(_TextField);
    end;

    procedure BlobOnValidate(_FieldNo: Integer; var _TextField: Text);
    var
        tmpTenantMedia: Record "Tenant Media" temporary;
        _FieldRef: FieldRef;
        _RecordRef: RecordRef;
        _OutStream: OutStream;
    begin
        if _TextField <> '' then begin
            _RecordRef.GetTable(Rec);
            _FieldRef := _RecordRef.Field(_FieldNo);
            tmpTenantMedia.Content.CreateOutStream(_OutStream);
            _OutStream.WriteText(_TextField);
            _FieldRef.Value := tmpTenantMedia.Content;
            _RecordRef.Modify;
        end;
    end;
    // <<<

    // >>
    // procedure SetTextToBlobField(newValueToBlob: Text; _FieldNo: Integer)
    // var
    //     _outStream: OutStream;
    //     ItemDescRecRef: RecordRef;
    //     ItemDescFieldRef: FieldRef;
    // begin
    //     if newValueToBlob = '' then exit;
    //     ItemDescRecRef.GetTable(Rec);
    //     ItemDescFieldRef := ItemDescRecRef.Field(_FieldNo);
    //     ItemDescFieldRef.Value(newValueToBlob);
    //     if ItemDescRecRef.MODIFY then;
    // end;

    // procedure GetTextFromBlobField(_FieldNo: Integer): Text
    // var
    //     _outStream: OutStream;
    //     ItemDescRecRef: RecordRef;
    //     ItemDescFieldRef: FieldRef;
    // begin
    //     ItemDescRecRef.GetTable(Rec);
    //     ItemDescFieldRef := ItemDescRecRef.Field(_FieldNo);
    //     ItemDescFieldRef.CalcField();
    //     if ItemDescFieldRef.Length = 0 then exit('');
    //     exit(ItemDescFieldRef.Value);
    // end;
    // <<

    procedure SetTextToBlobField(_FieldNo: Integer; _TextField: Text);
    var
        tmpTenantMedia: Record "Tenant Media" temporary;
        _FieldRef: FieldRef;
        _RecordRef: RecordRef;
        _OutStream: OutStream;
    begin
        if _TextField <> '' then begin
            _RecordRef.GetTable(Rec);
            _FieldRef := _RecordRef.Field(_FieldNo);
            tmpTenantMedia.Content.CreateOutStream(_OutStream);
            _OutStream.WriteText(_TextField);
            _FieldRef.Value := tmpTenantMedia.Content;
            _RecordRef.Modify;
        end;
    end;

    procedure GetTextFromBlobField(_FieldNo: Integer): Text
    var
        tmpTenantMedia: Record "Tenant Media" temporary;
        _FieldRef: FieldRef;
        _RecordRef: RecordRef;
        _InStream: InStream;
        _TextField: Text;
    begin
        _RecordRef.GetTable(Rec);
        _FieldRef := _RecordRef.Field(_FieldNo);
        _FieldRef.CalcField();
        tmpTenantMedia.Content := _FieldRef.Value;
        if not tmpTenantMedia.Content.HasValue then
            _TextField := ''
        else begin
            tmpTenantMedia.Content.CreateInStream(_InStream);
            _InStream.ReadText(_TextField);
        end;
        exit(_TextField);
    end;

    var
        Text001: TextConst ENU = 'This will overwrite the contents of this field. Are you sure?';
        Text002: TextConst ENU = 'Select the Txt file';
        Text003: TextConst ENU = 'C:\Temp';
        Text004: TextConst ENU = 'Txt File *.txt| *.txt';
        Text005: TextConst ENU = 'File Successfully Uploaded';
}