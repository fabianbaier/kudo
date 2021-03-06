/*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// FrameworkSpec defines the desired state of Framework
type FrameworkSpec struct {
	Description       string       `json:"description,omitempty"`
	KudoVersion       string       `json:"kudoVersion,omitempty"`
	KubernetesVersion string       `json:"kubernetesVersion,omitempty"`
	Maintainers       []Maintainer `json:"maintainers,omitempty"`
	URL               string       `json:"url,omitempty"`
}

// Maintainer contains contact info for the maintainer of the Framework
type Maintainer string

// FrameworkStatus defines the observed state of Framework
type FrameworkStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
}

// +genclient
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// Framework is the Schema for the frameworks API
// +k8s:openapi-gen=true
type Framework struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   FrameworkSpec   `json:"spec,omitempty"`
	Status FrameworkStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// FrameworkList contains a list of Framework
type FrameworkList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Framework `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Framework{}, &FrameworkList{})
}
