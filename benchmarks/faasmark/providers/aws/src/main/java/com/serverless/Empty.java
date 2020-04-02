package com.serverless;

import java.util.Map;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

public class Empty implements RequestHandler<Map<String,String>, String> {
	@Override
    public String handleRequest(Map<String,String> event, Context context) {
		return "{\"StatusCode\":200,\"body\":\"\"}";
	}
}
