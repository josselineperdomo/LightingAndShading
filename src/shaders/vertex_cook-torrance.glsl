#version 400

#define MAX_LIGHTS 3
#define TRUE 1

#define pi 3.14159265358979f

layout(location = 0) in vec3 Vertex;
layout(location = 1) in vec3 Normal;

layout(location = 2) in vec3 m_ambient;
layout(location = 3) in vec3 m_diffuse;
layout(location = 4) in vec3 m_specular;
layout(location = 5) in float m_shininess;
layout(location = 6) in float m_reflectance;
layout(location = 7) in float m_roughness;

struct Light{
	vec4 position;
	vec3 diffuse;
	vec3 specular;
	float constantAtt; 
	float linearAtt; 
	float quadraticAtt; 
	float cutoff;
	float exponent;
	vec3 direction; 
	int active;
};
uniform Light Lights[MAX_LIGHTS]; // Light sources
uniform vec3 l_ambient; // Ambient light

uniform mat4 ModelViewProjection;
uniform mat4 ModelView;
uniform mat3 NormalMatrix;

out vec3 color;

vec3 normal, position, view;

vec3 Intensity(int index){
	vec3 halfv, light;
	vec3 diffuse, specular;
	float att, dist, cos_cutoff, cos_angle, intensity;
	float fresnel, roughness, geometric;
	float NdotH, NdotV, NdotL, HdotV, HdotL; 
	
	att = 1.f;
	if(Lights[index].position.w == 0.f) // Directional light
		light = normalize(Lights[index].direction);
	else{ // Light from a specific spot or a spotlight
		light = Lights[index].position.xyz - position;
		dist = length(light);
		light = normalize(light);
		att /= Lights[index].constantAtt + Lights[index].linearAtt*dist + Lights[index].quadraticAtt*dist*dist;
		if(Lights[index].cutoff<=90.f){
			cos_angle = max(dot(-light, normalize(Lights[index].direction)), 0.f);
			cos_cutoff = cos(radians(Lights[index].cutoff));
			att = (cos_angle<cos_cutoff)?0.f:att*pow(cos_angle, Lights[index].exponent);
		}
	}
	halfv = normalize(light+view);
	NdotL = dot(normal, light);
	
	diffuse = specular = vec3(0.f);
	intensity = max(NdotL, 0.f);
	if(intensity>0.f){
		diffuse = Lights[index].diffuse*m_diffuse*intensity;
		// Calculating specular reflection
		NdotH = dot(normal, halfv);
		NdotV = dot(normal, view);
		HdotV = dot(halfv, view);
		HdotL = dot(halfv, light);
		geometric = min(1, min(2.f*NdotH*NdotV/HdotV, 2.f*NdotH*NdotL/HdotL));
		fresnel = m_reflectance+(1.f-m_reflectance)*(1.f-HdotV)*(1.f-HdotV)*(1.f-HdotV)*(1.f-HdotV)*(1.f-HdotV);
		roughness = exp((NdotH*NdotH-1)/(m_roughness*m_roughness*NdotH*NdotH))/(pi*m_roughness*m_roughness*NdotH*NdotH*NdotH*NdotH);
		intensity = (geometric*fresnel*roughness)/(NdotV*NdotL);
		if(intensity>0.f)
			specular = Lights[index].specular*m_specular*NdotL*intensity;
	}
	return att*(diffuse+specular);
}

void main(){
	normal = normalize(NormalMatrix*Normal);
	position = (ModelView*vec4(Vertex,1.f)).xyz;
	view = normalize(-position);
	
	color = l_ambient*m_ambient;
	for(int i=0;i<MAX_LIGHTS;++i){
		if(Lights[i].active==TRUE)
			color += Intensity(i); 
	}
	gl_Position = ModelViewProjection*vec4(Vertex,1.f);
}