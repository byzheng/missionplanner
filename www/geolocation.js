

function getip() {
ip = null;
$.getJSON("//api.ipinfodb.com/v3/ip-city/?key=12e14e83d1abccf95a3c109dd60e7675dd4073d4ccbe3a8895f8b9212e19868b&format=json&callback=?",
  function(data){
	  Shiny.onInputChange('ip_address', data);
});

}
