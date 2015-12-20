package io.pivotal.demo.sko;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(value = "/controller")
public class DummyController {
	
    @RequestMapping(value="/getHealth")
    public @ResponseBody boolean isAppUp(){
    	return true;
    }

}
