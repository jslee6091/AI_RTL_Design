from django import forms
from .models import Post, Comment


# validation 을 클래스에서 안하고 models.py 에서 함
class PostModelForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ('title', 'text',)


# title 입력필드의 길이 체크
def min_length_3_validator(value):
    if len(value) < 3:
        raise forms.ValidationError('Title 은 3글자 이상 입력해주세요')


# class 에서 validation 을 함
# PostModelForm 과 다른 경우임
class PostForm(forms.Form):
    title = forms.CharField(validators=[min_length_3_validator])
    text = forms.CharField(widget=forms.Textarea)


class CommentForm(forms.ModelForm):
    class Meta:
        model = Comment
        fields = ('author', 'text',)
