Call Include("utils")

Function make_winding()
  lx1 = -slot_teeth_width/2+coil_core_separation_x
  rx1 = -slot_teeth_width/2+coil_core_separation_x+coil_width
  by1 = coil_core_separation_y
  ty1 = coil_core_separation_y+coil_height
  lx2 = lx1+distribute_distance*slot_pitch
  rx2 = rx1+distribute_distance*slot_pitch
  by2 = slot_height-ty1
  ty2 = slot_height-by1

  Call view.newLine(lx1,by1,rx1,by1)
  Call view.newLine(lx1,ty1,rx1,ty1)
  Call view.newLine(lx1,by1,lx1,ty1)
  Call view.newLine(rx1,by1,rx1,ty1)

  Call view.newLine(lx2,by2,rx2,by2)
  Call view.newLine(lx2,ty2,rx2,ty2)
  Call view.newLine(lx2,by2,lx2,ty2)
  Call view.newLine(rx2,by2,rx2,ty2)

  Call view.getSlice().moveInALine(length_core/2)

  Dim coil_p1_name
  Dim coil_p2_name
  Dim coil_name

  coil_p1_name = "Coil#1p1"
  coil_p2_name = "Coil#1p2"
  coil_name = "Coil#1"
  copy_keyword = " Copy#"
  union_keyword = " Union#"

  init_coords = Array((lx1+rx1)/2,(by1+ty1)/2,0)
  unit_x_vec = Array(1,0,0)
  unit_y_vec = Array(0,1,0)
  unit_z_vec = Array(0,0,1)

  frame_params = Array("Frame","Cartesian",init_coords,unit_x_vec,unit_y_vec,unit_z_vec)
  start_frame = Array("Start")
  blend_frame = Array("Blend","Automatic")

  line_frame_1 = Array("Line",Array(0,0,length_core/2+coil_core_separation_x))
  line_frame_2 = Array("Line",Array(((lx2+rx2)/2-(lx1+rx1)/2)/2,0,length_core/2+coil_core_separation_x+end_ext))
  line_frame_3 = Array("Line",Array(((lx2+rx2)/2-(lx1+rx1)/2)/2,0,length_core/2+coil_core_separation_x+end_ext+coil_width))
  arc_frame_4 = Array("Arc",180,Array(((lx2+rx2)/2-(lx1+rx1)/2)/2,(ty2+by2)/4-(ty1+by1)/4,length_core/2+coil_core_separation_x+end_ext+coil_width),Array(-1,0,0))
  line_frame_5 = Array("Line",Array(((lx2+rx2)/2-(lx1+rx1)/2)/2,(ty2+by2)/2-(ty1+by1)/2,length_core/2+coil_core_separation_x))
  line_frame_6 = Array("Line",Array((lx2+rx2)/2-(lx1+rx1)/2,(ty2+by2)/2-(ty1+by1)/2,length_core/2+coil_core_separation_x))

  multi_sweep_params = Array(frame_params,start_frame,line_frame_1,blend_frame,line_frame_2,blend_frame,line_frame_3,blend_frame,arc_frame_4)'',blend_frame,line_frame_5)'',blend_frame,line_frame_6)'',blend_frame,line_frame_7)

  Call view.selectAt((lx1+rx1)/2,(ty1+by1)/2, infoSetSelection, Array(infoSliceSurface))
  Call view.makeComponentInAMultiSweep(multi_sweep_params,Array(coil_p1_name),format_material(coil_material),infoMakeComponentUnionSurfaces Or infoMakeComponentRemoveVertices)

  line_frame_7 = Array("Line",Array((lx2+rx2)/2-(lx1+rx1)/2,(ty2+by2)/2-(ty1+by1)/2,length_core/2+coil_core_separation_x))
  line_frame_8 = Array("Line",Array(((lx2+rx2)/2-(lx1+rx1)/2)/2,(ty2+by2)/2-(ty1+by1)/2,length_core/2+coil_core_separation_x+end_ext))
  line_frame_9 = Array("Line",Array(((lx2+rx2)/2-(lx1+rx1)/2)/2,(ty2+by2)/2-(ty1+by1)/2,length_core/2+coil_core_separation_x+end_ext+coil_width))

  multi_sweep_params = Array(frame_params,start_frame,line_frame_7,blend_frame,line_frame_8,blend_frame,line_frame_9)

  Call view.selectAt((lx2+rx2)/2,(ty2+by2)/2, infoSetSelection, Array(infoSliceSurface))
  Call view.makeComponentInAMultiSweep(multi_sweep_params,Array(coil_p2_name),format_material(coil_material),infoMakeComponentUnionSurfaces Or infoMakeComponentRemoveVertices)

  'Merge Coil Parts (Forms one side of single winding)'
  coil_parts = Array(coil_p1_name,coil_p2_name)
  Call getDocument().beginUndoGroup("Union Coil Parts")
  If (getDocument().unionComponents(coil_parts,2,ErrorMessages) <> "") Then
    Call getDocument().getView().selectObject(coil_p1_name, infoSetSelection)
    Call getDocument().getView().selectObject(coil_p2_name, infoAddToSelection)
    Call getDocument().getView().deleteSelection()
  Else
    Call getDocument().getView().unselectAll()
    Call getApplication().MsgBox("An error occurred doing the union operation:" & vbLf & ErrorMessages, vbOKOnly)
  End If
  Call getDocument().endUndoGroup()

  'Mirror Single-sided Coil (Forms full single winding in two separate components)'
  component_name = coil_p1_name+"+"+coil_p2_name+union_keyword+"1"
  Call getDocument().beginUndoGroup("Mirror Component")
  Call getDocument().mirrorComponent(getDocument().copyComponent(Array(component_name), 1), 0, 0, 0, 0, 0, 1, 1)
  Call getDocument().endUndoGroup()

  'Union both coil sides (Form full single winding)'
  coil_halves = Array(component_name,component_name+copy_keyword+"1")
  Call getDocument().beginUndoGroup("Union Components")
  If (getDocument().unionComponents(coil_halves,2,ErrorMessages) <> "") Then
    Call getDocument().getView().selectObject(component_name, infoSetSelection)
    Call getDocument().getView().selectObject(component_name+copy_keyword+"1", infoAddToSelection)
    Call getDocument().getView().deleteSelection()
  Else
    Call getDocument().getView().unselectAll()
    Call getApplication().MsgBox("An error occurred doing the union operation:" & vbLf & ErrorMessages, vbOKOnly)
  End If
  Call getDocument().endUndoGroup()

  'Rename Component'
  Dim final_name
  final_component_name = component_name+"+"+component_name+copy_keyword+"1"+union_keyword+"1"
  Call getDocument().beginUndoGroup("Set Coil Properties", true)
  Call getDocument().renameObject(final_component_name,coil_name)
  Call getDocument().endUndoGroup()
  make_winding = coil_name
End Function


Function make_windings(winding_name)
  Call getDocument().beginUndoGroup("Transform Component")

  Dim component_name
  copy_keyword = " Copy#1"

  For i=1 to num_coils-1
    Call getDocument().shiftComponent(getDocument().copyComponent(Array(winding_name),1),slot_pitch*i, 0, 0, 1)
    component_name = Replace(winding_name,"1",i+1)
    Call getDocument().renameObject(winding_name+Replace(copy_keyword,"1",i),component_name)
  Next
  Call getDocument().endUndoGroup()
  Call clear_construction_lines()
End Function


Sub Include(file)

  Dim fso, f
  Set fso = CreateObject("Scripting.FileSystemObject")
  Set f = fso.OpenTextFile(file & ".vbs", 1)
  ExecuteGlobal f.ReadAll
  f.Close
  'ExecuteGlobal str
End Sub
