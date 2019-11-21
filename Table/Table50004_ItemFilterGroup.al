table 50004 "Item Filter Group"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
        field(2; "Filter Group"; Text[50])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
        field(3; "Filter Value"; Text[100])
        {
            DataClassification = ToBeClassified;
            TableRelation = Item;
        }
    }

    keys
    {
        key(PK; "Item No.", "Filter Group", "Filter Value")
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

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

}