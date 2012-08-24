$(document).ready(function(){
	$("#blacklight_nearby_items_controls .navigation").live("click",function(){
		$.ajax({url: $(this).attr("href") + "&format=js"});
		return false;
	});
});