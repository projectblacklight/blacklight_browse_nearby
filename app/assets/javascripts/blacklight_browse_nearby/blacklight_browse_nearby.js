$(document).ready(function(){
	$("#blacklight_nearby_items_controls .navigation").live("click",function(){
		$.ajax({url: $(this).attr("href") + "&format=js"});
		return false;
	});
	$("#browse_value_select button").toggle();
	$("#browse_value_select select").live("change", function(){
	  $.ajax({url: $("#browse_value_select").attr("action") + "&format=js&preferred_value=" + $(this).val()}).done(function(){
		  $("#blacklight_nearby_items_controls .ful_browse").attr("href", $("#blacklight_nearby_items_controls .ful_browse").attr("href") + "&preferred_value=" + $(this).val())
		});
	});
});