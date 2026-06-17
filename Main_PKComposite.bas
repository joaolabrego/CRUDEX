Option Explicit

Public Sub Recalcule()
    Application.CalculateFull
End Sub

Private Function NormalizeHeader(ByVal header As String) As String
   header = Trim$(CStr(header))
   If Left$(header, 1) = "*" Then
      header = Mid$(header, 2)
   End If
   NormalizeHeader = header
End Function

Private Function ArgValue(ByVal v As Variant) As Variant
   If IsObject(v) Then
      If TypeName(v) = "Range" Then
         ArgValue = v.Cells(1, 1).Value
      Else
         ArgValue = v
      End If
   Else
      ArgValue = v
   End If
End Function

Private Function FindWorksheet(ByVal worksheetName As String) As Worksheet
   Dim i As Long

   For i = 1 To Application.Worksheets.Count
      If Application.Worksheets(i).Name = worksheetName Then
         Set FindWorksheet = Application.Worksheets(i)
         Exit Function
      End If
      DoEvents
   Next
   Err.Raise 1000, , "FindWorksheet: Nome de planilha '" & worksheetName & "' não encontrado!"
End Function

Private Function PkColumnCount(ByRef plan As Worksheet) As Long
   Dim col As Long, hdr As String, n As Long

   col = 1
   Do While plan.Cells(1, col).Value <> vbNullString
      hdr = Trim$(CStr(plan.Cells(1, col).Value))
      If Left$(hdr, 1) = "*" Then n = n + 1
      col = col + 1
      DoEvents
   Loop
   PkColumnCount = n
End Function

Private Function PkColumnAt(ByRef plan As Worksheet, ByVal index As Long) As Long
   Dim col As Long, hdr As String, n As Long

   col = 1
   Do While plan.Cells(1, col).Value <> vbNullString
      hdr = Trim$(CStr(plan.Cells(1, col).Value))
      If Left$(hdr, 1) = "*" Then
         n = n + 1
         If n = index Then
            PkColumnAt = col
            Exit Function
         End If
      End If
      col = col + 1
      DoEvents
   Loop
   Err.Raise 1000, , "PkColumnAt: índice PK inválido em '" & plan.Name & "'."
End Function

Private Function FindRowByPkValues(ByRef plan As Worksheet, ByRef keyValues() As Variant, ByVal pkCount As Long) As Long
   Dim i As Long, row As Long, col As Long
   Dim ok As Boolean, keyVal As Variant

   row = 2
   Do
      If plan.Cells(row, 1) = vbNullString Then
         Err.Raise 1000, , "FindRow: registro não encontrado em '" & plan.Name & "'."
      End If
      ok = True
      For i = 1 To pkCount
         col = PkColumnAt(plan, i)
         keyVal = ArgValue(keyValues(i - 1))
         If plan.Cells(row, col).Value <> keyVal Then
            ok = False
            Exit For
         End If
      Next i
      If ok Then
         FindRowByPkValues = row
         Exit Function
      End If
      row = row + 1
      DoEvents
   Loop
End Function

Private Sub CopyPkValues(ByVal keyValues As Variant, ByRef keys() As Variant, ByVal pkCount As Long)
   Dim i As Long, lb As Long

   lb = LBound(keyValues)
   ReDim keys(0 To pkCount - 1)
   For i = 0 To pkCount - 1
      keys(i) = keyValues(lb + i)
   Next i
End Sub

Public Function FindRow(ByRef plan As Worksheet, ParamArray keyValues() As Variant) As Long
   Dim pkCount As Long, keyCount As Long
   Dim keys() As Variant

   keyCount = UBound(keyValues) - LBound(keyValues) + 1
   pkCount = PkColumnCount(plan)
   If pkCount = 0 Then
      Err.Raise 1000, , "FindRow: nenhuma coluna PK (*) em '" & plan.Name & "'."
   End If
   If keyCount <> pkCount Then
      Err.Raise 1000, , "FindRow: esperados " & pkCount & " valor(es) de PK, recebidos " & keyCount & "."
   End If
   CopyPkValues keyValues, keys, pkCount
   FindRow = FindRowByPkValues(plan, keys, pkCount)
End Function

Public Function FindColumn(ByRef plan As Worksheet, ByVal columnName As String) As Long
   Dim wanted As String

   wanted = NormalizeHeader(columnName)
   FindColumn = 1
   Do
      If plan.Cells(1, FindColumn) = vbNullString Then
         Err.Raise 1000, , "FindColumn: Nome de coluna '" & columnName & "' não encontrado!"
      End If
      If NormalizeHeader(CStr(plan.Cells(1, FindColumn).Value)) = wanted Then
         Exit Do
      End If
      FindColumn = FindColumn + 1
      DoEvents
   Loop
End Function

Public Function GetValue(ByVal worksheetName As String, ByVal columnName As String, ParamArray keyValues() As Variant) As Variant
   Dim plan As Worksheet, row As Long, col As Long
   Dim keyCount As Long, pkCount As Long, firstKey As Variant
   Dim keys() As Variant

   keyCount = UBound(keyValues) - LBound(keyValues) + 1
   If keyCount = 0 Then
      GetValue = vbNullString
      Exit Function
   End If

   firstKey = ArgValue(keyValues(LBound(keyValues)))
   If firstKey = 0 Or firstKey = vbNullString Then
      GetValue = vbNullString
      Exit Function
   End If

   Set plan = FindWorksheet(worksheetName)
   pkCount = PkColumnCount(plan)
   If pkCount = 0 Then
      Err.Raise 1000, , "GetValue: nenhuma coluna PK (*) em '" & worksheetName & "'."
   End If
   If keyCount <> pkCount Then
      Err.Raise 1000, , "GetValue: esperados " & pkCount & " valor(es) de PK, recebidos " & keyCount & "."
   End If

   CopyPkValues keyValues, keys, pkCount
   row = FindRowByPkValues(plan, keys, pkCount)
   col = FindColumn(plan, columnName)
   GetValue = plan.Cells(row, col).Value

   If columnName = "Name" Then
      If worksheetName = "Types" Then
         col = FindColumn(plan, "IsActive")
         GetValue = GetValue + IIf(plan.Cells(row, col), "", " (INATIVO)")
      ElseIf worksheetName = "Columns" Then
         col = FindColumn(plan, "TableId")
         GetValue = GetValue + " (" & GetValue("Tables", "Name", plan.Cells(row, col)) & ")"
      End If
   End If
End Function

Public Function GetLastId(ByVal tableId As Long) As Long
   Dim plan As Worksheet, row As Long, col As Long

   row = 2
   col = FindColumn(planTables, "Id")
   Do While planTables.Cells(row, col) <> vbNullString And planTables.Cells(row, col) <> tableId
      row = row + 1
      DoEvents
   Loop
   If planTables.Cells(row, col) = vbNullString Then
      Err.Raise 1000, , "GetLastId: Id de tabela não encontrado."
   End If
   col = FindColumn(planTables, "Name")
   Set plan = FindWorksheet(planTables.Cells(row, col))

   row = 2
   col = PkColumnAt(plan, 1)
   Do While plan.Cells(row, col) <> vbNullString
      GetLastId = plan.Cells(row, col)
      row = row + 1
      DoEvents
   Loop
End Function

Public Function GetDataType(ByVal domainId As Long) As String
   Dim rowDomain As Long, colTypeId As Long, colLength As Long, colDecimals As Long, rowType As Long, colName As Long

   rowDomain = FindRow(planDomains, domainId)
   colTypeId = FindColumn(planDomains, "TypeId")
   colLength = FindColumn(planDomains, "Length")
   colDecimals = FindColumn(planDomains, "Decimals")
   rowType = FindRow(planTypes, planDomains.Cells(rowDomain, colTypeId))
   colName = FindColumn(planTypes, "Name")
   GetDataType = planTypes.Cells(rowType, colName)
   If Val(planDomains.Cells(rowDomain, colLength)) > 0 Then
      GetDataType = GetDataType & "(" & planDomains.Cells(rowDomain, colLength)
      If Val(planDomains.Cells(rowDomain, colDecimals)) > 0 Then
         GetDataType = GetDataType & ", " & planDomains.Cells(rowDomain, colDecimals)
      End If
      GetDataType = GetDataType & ")"
   End If
End Function

Public Function DatabaseId(ByVal tableId As Long) As Long
   Dim row As Long, col As Long

   row = 2
   col = FindColumn(planDatabasesTables, "TableId")
   Do While planDatabasesTables.Cells(row, col) <> vbNullString
      If planDatabasesTables.Cells(row, col) = tableId Then
         DatabaseId = planDatabasesTables.Cells(row, FindColumn(planDatabasesTables, "DatabaseId"))
         Exit Function
      End If
      row = row + 1
      DoEvents
   Loop
   Err.Raise 1000, , "DatabaseId: Id de banco-de-dados não encontrado."
End Function

Public Sub ConferirColunas()
    Dim linha As Long, coluna As Long, plan As Worksheet, i As Long, value1 As Variant, value2 As Variant

    On Error GoTo Erro
    linha = 2

    For i = 1 To Worksheets.Count
        Set plan = Worksheets(i)
        coluna = 1
        Do While plan.Cells(1, coluna) <> ""
           value1 = Trim(plan.Cells(1, coluna))
           value2 = Trim(planColumns.Cells(linha, 13))
           If Left(value1, 1) = "#" Then
              coluna = coluna + 1
           ElseIf NormalizeHeader(value1) = value2 Then
              If planColumns.Cells(linha, 3) <> plan.Name Then
                 Err.Raise 1000, , "Nome de tabela não bate."
              End If
              linha = linha + 1
              coluna = coluna + 1
           Else
              Err.Raise 1000, , "Nome de coluna não bate."
           End If
        Loop
    Next
    MsgBox "ok"
    Exit Sub
Erro:
    MsgBox Err.Description + " (" + planColumns.Cells(linha, 3) + "/" + plan.Name + "-" + value1 + "-" + value2 + ")"
End Sub
