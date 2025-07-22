Dans ```web/templates/submision/index.html```

In the ```<script>``` section  
```js
$(document).ready( function() {
    // URL is default
    $('.nav-tabs a[href="#url"]').tab('show');

    // ....

    $('.nav-tabs a').on('show.bs.tab', function (event) {
            const defaultMachine = $(event.target).data('default-machine');
            if (defaultMachine) {
                $('#form_machine').val(defaultMachine);
            }
        //...
    });

    // ......
});
```


And in the type select of the submit, with ```data-default-machine``` being the VM name.  

```html
<ul class="nav nav-tabs">
    {% if resubmit %}
        <li class="nav-item active"><a class="nav-link" href="#resubmit" data-toggle="tab"><span class="fa fa-file"></span> File resubmission</a></li>
    {% else %}
        <li class="nav-item active"><a class="nav-link" href="#file" data-toggle="tab" data-default-machine="win10-malware"><span class="fa fa-file"></span> File(s)</a></li>
        {% if config.downloading_service %}
            <li class="nav-item"><a class="nav-link" href="#downloading_service" data-toggle="tab"><span class="fa fa-download"></span> Download</a></li>
        {% endif %}
        {% if config.url_analysis %}
            <li class="nav-item"><a class="nav-link" href="#url" data-toggle="tab" data-default-machine="win10-url"><span class="fa fa-globe"></span> URL</a></li>
        {% endif %}
        {% if config.dlnexec %}
            <li class="nav-item"><a class="nav-link" href="#dlurl" data-toggle="tab"><span class="fa fa-download"></span> DL&Exec</a></li>
        {% endif %}
        <li class="nav-item"><a class="nav-link" href="#pcap" data-toggle="tab"><span class="fa fa-network-wired"></span> PCAP</a></li>
        <li class="nav-item"><a class="nav-link" href="#static" data-toggle="tab"><span class="fa fa-tasks"></span> Static</a></li>
    {% endif %}
</ul>
```

Then, in the machine selection form, replace with the code below to select by default the machine whose name contains url.  
This will be overwritten when a type is selected.  

```html
<div class="form-group">
    <label for="form_machine">Machine (choisir : URL vs FICHIER)</label>
    <select class="form-control" id="form_machine" name="machine">
        {% for id, label in machines %}
            {% if "url" in id %}
                <option value="{{ id }}" selected>{{ label }}</option>
            {% else %}
                <option value="{{ id }}">{{ label }}</option>
            {% endif %}
        {% endfor %}
    </select>
</div>
```
