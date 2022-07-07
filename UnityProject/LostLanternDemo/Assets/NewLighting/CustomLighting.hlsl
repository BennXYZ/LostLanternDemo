#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

struct CustomLightingData {
	float3 normalWS;
	float3 viewDirectionWS;
	float4 shadowCoord;
	float3 positionWS;

	float3 albedo;
	float smoothness;
	float ambientOcclusion;

	float3 bakedGI;
	float fogFactor;
};

float GetSmoothnessPower(float rawSmoothness) {
	return exp2(10 * rawSmoothness + 1);
}

#ifndef SHADERGRAPH_PREVIEW
float3 CustomGlobalIllumination(CustomLightingData d) {
	float3 indirectDiffuse = d.albedo * d.bakedGI * d.ambientOcclusion;

	float3 reflectVector = reflect(-d.viewDirectionWS, d.normalWS);
	float fresnel = Pow4(1 - saturate(dot(d.viewDirectionWS, d.normalWS)));
	//float3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, RoughnessToPerceptualRoughness(1 - d.smoothness), d.ambientOcclusion) * fresnel;

	//return indirectDiffuse + indirectSpecular;
	return indirectDiffuse;
}

float3 CustomLightHandling(CustomLightingData d, Light light) {
	float3 radiance = light.color * light.shadowAttenuation * light.shadowAttenuation;

	float diffuse = saturate(dot(d.normalWS, light.direction));
	float specularDot = saturate(dot(d.normalWS, normalize(light.direction + d.viewDirectionWS)));
	float specular = pow(specularDot, GetSmoothnessPower(d.smoothness)) * diffuse;
	//float specular = pow(specularDot, GetSmoothnessPower(d.smoothness)) * diffuse;

	float3 color = d.albedo * radiance * (diffuse);
	//float3 color = d.albedo * radiance * (diffuse + specular);

	return color;
}
#endif

float3 CalculateCustomLighting(CustomLightingData d) {
#ifdef SHADERGRAPH_PREVIEW
	float3 lightDir = float3(0.5, 0.5, 0);
	float intensity = saturate(dot(d.normalWS, lightDir)) + 
		saturate(dot(d.normalWS, normalize(d.viewDirectionWS + lightDir)));
		//pow(saturate(dot(d.normalWS, normalize(d.viewDirectionWS + lightDir))), GetSmoothnessPower(d.smoothness));
	return d.albedo * intensity;
#else
	Light mainLight = GetMainLight(d.shadowCoord, d.positionWS, 1);
	MixRealtimeAndBakedGI(mainLight, d.normalWS, d.bakedGI);

	float3 color = CustomGlobalIllumination(d);

	color += CustomLightHandling(d, mainLight);

#ifdef _ADDITIONAL_LIGHTS
	uint numAdditionalLights = GetAdditionalLightsCount();
	for (uint lightI = 0; lightI < numAdditionalLights; lightI++) {
		Light light = GetAdditionalLight(lightI, d.positionWS, 1);
		color += CustomLightHandling(d, light);
	}
#endif
	color = MixFog(color, d.fogFactor);
	return color;
#endif
}

void CalculateCustomLighting_float(float3 Albedo, float3 Normal, float3 ViewDirection, float3 Position, float Smoothness, float AmbientOcclusion, 
	float2 LightmapUV, float FogFactor, out float3 Color) {
	CustomLightingData d;

	d.albedo = Albedo;
	d.normalWS = Normal;
	d.viewDirectionWS = ViewDirection;
	//d.smoothness = Smoothness;
	d.positionWS = Position;
	d.ambientOcclusion = AmbientOcclusion;


#ifdef SHADERGRAPH_PREVIEW
	d.shadowCoord = 0;
	d.bakedGI = 0;
	d.fogFactor = 0;
#else
	float4 positionCS = TransformWorldToHClip(Position);
#if SHADOWS_SCREEN
	d.shadowCoord = ComputeScreenPos(positionCS);
#else
	d.shadowCoord = TransformWorldToShadowCoord(Position);
#endif

	float3 lightmapUV;
	OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, lightmapUV);
	float3 vertexSH;
	OUTPUT_SH(Normal, vertexSH);
	d.bakedGI = SAMPLE_GI(lightmapUV, vertexSH, Normal);
	d.fogFactor = ComputeFogFactor(positionCS.z);
#endif

	Color = CalculateCustomLighting(d);
}

#endif