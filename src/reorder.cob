       >>source format free
identification division.
program-id. stock-reorder.
environment division.
input-output section.
file-control.
    select stock-file assign to input-name
        organization is line sequential
        file status is input-status.
data division.
file section.
fd stock-file.
01 input-line pic x(4096).
working-storage section.
01 input-name pic x(1024).
01 input-status pic xx.
01 argument-count binary-long.
01 finished pic 9 value 0.
01 rejected-count binary-long value 0.
01 line-number pic 9(9) value 0.
01 line-display pic z(8)9.
01 quantity-display pic z(5)9.
01 sku pic x(10).
01 current-stock pic 9(6).
01 minimum-stock pic 9(6).
01 target-stock pic 9(6).
01 reorder-units pic 9(6).
01 reason pic x(32).
01 decision pic x(12).
01 position-index binary-long.
01 current-character pic x.
procedure division.
main.
    accept argument-count from argument-number
    if argument-count not = 1
        display "usage: stock-reorder INPUT.txt" upon stderr
        move 1 to return-code
        goback
    end-if
    accept input-name from argument-value
    open input stock-file
    if input-status not = "00"
        display "cannot open input: status " input-status upon stderr
        move 1 to return-code
        goback
    end-if
    display "line,status,sku,reorder_units,reason"
    perform until finished = 1
        read stock-file
        evaluate input-status
            when "10" move 1 to finished
            when "00"
                add 1 to line-number
                perform process-record
            when other
                display "input read failed: status " input-status upon stderr
                close stock-file
                move 1 to return-code
                goback
        end-evaluate
    end-perform
    close stock-file
    if input-status not = "00"
        display "input close failed" upon stderr
        move 1 to return-code
    else
        if rejected-count > 0
            move 2 to return-code
        else
            move 0 to return-code
        end-if
    end-if
    goback.

process-record.
    move spaces to reason
    move input-line(1:10) to sku
    move zero to reorder-units
    move "REJECT" to decision
    if function length(function trim(input-line trailing)) not = 28
        move "record-length" to reason
    end-if
    if reason = spaces and sku = spaces
        move "blank-sku" to reason
    end-if
    if reason = spaces
        perform varying position-index from 1 by 1 until position-index > 10
            move sku(position-index:1) to current-character
            if not ((current-character >= "A" and current-character <= "Z")
                or (current-character >= "0" and current-character <= "9")
                or current-character = "-" or current-character = space)
                move "invalid-sku" to reason
            end-if
        end-perform
    end-if
    if reason = spaces
        if input-line(11:6) is not numeric
            or input-line(17:6) is not numeric
            or input-line(23:6) is not numeric
            move "non-numeric-units" to reason
        end-if
    end-if
    if reason = spaces
        move input-line(11:6) to current-stock
        move input-line(17:6) to minimum-stock
        move input-line(23:6) to target-stock
        if target-stock < minimum-stock
            move "target-below-minimum" to reason
        else
            move "KEEP" to decision
            if current-stock < minimum-stock
                compute reorder-units = target-stock - current-stock
                move "ORDER" to decision
            end-if
        end-if
    end-if
    if reason not = spaces
        add 1 to rejected-count
        *> Invalid identifiers are withheld to preserve the CSV field structure.
        if reason = "invalid-sku" or reason = "record-length"
            move spaces to sku
        end-if
    end-if
    move line-number to line-display
    move reorder-units to quantity-display
    display function trim(line-display) ","
        function trim(decision) "," function trim(sku) ","
        function trim(quantity-display) "," function trim(reason).
