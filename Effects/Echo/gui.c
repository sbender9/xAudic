#include <gtk/gtk.h>
#include "echo.h"

static const char echo_about_text[] = "Echo Plugin\n\n\
By Johan Levin 1999.";

GtkWidget	*conf_dialog = NULL, *echo_about_dialog = NULL;
GtkObject	*echo_delay_adj, *echo_feedback_adj, *echo_volume_adj;

static gint	echo_about_destroy_cb(GtkWidget *w, GdkEventAny *e, gpointer data)
{
	gtk_widget_destroy(echo_about_dialog);
	echo_about_dialog = NULL;
	return TRUE;
}

static void	echo_about_ok_cb(GtkButton *button, gpointer data)
{
	gtk_widget_destroy(GTK_WIDGET(echo_about_dialog));
	echo_about_dialog = NULL;
}

void	echo_about(void)
{
	GtkWidget	*hbox, *text, *button;

	if (echo_about_dialog != NULL)
		return;

	echo_about_dialog = gtk_dialog_new();
	gtk_signal_connect(GTK_OBJECT(echo_about_dialog), "destroy",
			GTK_SIGNAL_FUNC(echo_about_destroy_cb), NULL);
	gtk_window_set_title(GTK_WINDOW(echo_about_dialog), "Configure Extra Stero");

	hbox = gtk_hbox_new(FALSE, 0);
	gtk_box_pack_start(GTK_BOX(GTK_DIALOG(echo_about_dialog)->vbox), hbox,
			TRUE, TRUE, 5);
	gtk_widget_show(hbox);

	text = gtk_text_new(NULL, NULL);
	gtk_text_set_editable(GTK_TEXT(text), FALSE);
	gtk_text_insert(GTK_TEXT(text), NULL, NULL, NULL,
			echo_about_text, strlen(echo_about_text));
	gtk_box_pack_start(GTK_BOX(hbox), text, TRUE, TRUE, 5);
	gtk_widget_show(text);

	button = gtk_button_new_with_label("Ok");
	gtk_box_pack_start(GTK_BOX(GTK_DIALOG(echo_about_dialog)->action_area),
			button, TRUE, TRUE, 0);
	gtk_signal_connect(GTK_OBJECT(button), "clicked",
			GTK_SIGNAL_FUNC(echo_about_ok_cb), NULL);
	GTK_WIDGET_SET_FLAGS(button, GTK_CAN_DEFAULT);
	gtk_widget_grab_default(button);
	gtk_widget_show(button);
	gtk_widget_show(echo_about_dialog);
}

static gint	conf_destroy_cb(GtkWidget *w, GdkEventAny *e, gpointer data)
{
	gtk_widget_destroy(conf_dialog);
	conf_dialog = NULL;
	return TRUE;
}

static void	conf_ok_cb(GtkButton *button, gpointer data)
{
	echo_delay = GTK_ADJUSTMENT(echo_delay_adj)->value;
	echo_feedback = GTK_ADJUSTMENT(echo_feedback_adj)->value;
	echo_volume = GTK_ADJUSTMENT(echo_volume_adj)->value;
	gtk_widget_destroy(GTK_WIDGET(conf_dialog));
	conf_dialog = NULL;
}

static void	conf_cancel_cb(GtkButton *button, gpointer data)
{
	gtk_widget_destroy(GTK_WIDGET(conf_dialog));
	conf_dialog = NULL;
}

static void	conf_apply_cb(GtkButton *button, gpointer data)
{
	echo_delay = GTK_ADJUSTMENT(echo_delay_adj)->value;
	echo_feedback = GTK_ADJUSTMENT(echo_feedback_adj)->value;
	echo_volume = GTK_ADJUSTMENT(echo_volume_adj)->value;
}

void	echo_configure(void)
{
	GtkWidget	*button, *table, *label, *hscale;

	if (conf_dialog != NULL)
		return;

	conf_dialog = gtk_dialog_new();
	gtk_signal_connect(GTK_OBJECT(conf_dialog), "destroy",
			GTK_SIGNAL_FUNC(conf_destroy_cb), NULL);
	gtk_window_set_title(GTK_WINDOW(conf_dialog), "Configure Echo");

	echo_delay_adj = gtk_adjustment_new(echo_delay, 0, MAX_DELAY+100, 10, 100, 100);
	echo_feedback_adj = gtk_adjustment_new(echo_feedback, 0, 100+10, 2, 10, 10);
	echo_volume_adj = gtk_adjustment_new(echo_volume, 0, 100+10, 2, 10, 10);

	table = gtk_table_new(2, 3, FALSE);
	gtk_container_set_border_width(GTK_CONTAINER(table), 5);
	gtk_box_pack_start(GTK_BOX(GTK_DIALOG(conf_dialog)->vbox), table,
			TRUE, TRUE, 5);
	gtk_widget_show(table);

	label = gtk_label_new("Delay: (ms)");
	gtk_table_attach_defaults(GTK_TABLE(table), label, 0, 1, 0, 1);
	gtk_widget_show(label);

	label = gtk_label_new("Feedback: (%)");
	gtk_table_attach_defaults(GTK_TABLE(table), label, 0, 1, 1, 2);
	gtk_widget_show(label);

	label = gtk_label_new("Volume: (%)");
	gtk_table_attach_defaults(GTK_TABLE(table), label, 0, 1, 2, 3);
	gtk_widget_show(label);

	hscale = gtk_hscale_new(GTK_ADJUSTMENT(echo_delay_adj));
	gtk_widget_set_usize(hscale, 400, 35);
	gtk_table_attach_defaults(GTK_TABLE(table), hscale, 1, 2, 0, 1);
	gtk_widget_show(hscale);
	
	hscale = gtk_hscale_new(GTK_ADJUSTMENT(echo_feedback_adj));
	gtk_widget_set_usize(hscale, 400, 35);
	gtk_table_attach_defaults(GTK_TABLE(table), hscale, 1, 2, 1, 2);
	gtk_widget_show(hscale);
	
	hscale = gtk_hscale_new(GTK_ADJUSTMENT(echo_volume_adj));
	gtk_widget_set_usize(hscale, 400, 35);
	gtk_table_attach_defaults(GTK_TABLE(table), hscale, 1, 2, 2, 3);
	gtk_widget_show(hscale);
	
	button = gtk_button_new_with_label("Ok");
	gtk_box_pack_start(GTK_BOX(GTK_DIALOG(conf_dialog)->action_area), button,
			TRUE, TRUE, 0);
	gtk_signal_connect(GTK_OBJECT(button), "clicked",
			GTK_SIGNAL_FUNC(conf_ok_cb), NULL);
	GTK_WIDGET_SET_FLAGS(button, GTK_CAN_DEFAULT);
	gtk_widget_grab_default(button);
	gtk_widget_show(button);

	button = gtk_button_new_with_label("Cancel");
	gtk_box_pack_start(GTK_BOX(GTK_DIALOG(conf_dialog)->action_area), button,
			TRUE, TRUE, 0);
	gtk_signal_connect(GTK_OBJECT(button), "clicked",
			GTK_SIGNAL_FUNC(conf_cancel_cb), NULL);
	GTK_WIDGET_SET_FLAGS(button, GTK_CAN_DEFAULT);
	gtk_widget_show(button);

	button = gtk_button_new_with_label("Apply");
	gtk_box_pack_start(GTK_BOX(GTK_DIALOG(conf_dialog)->action_area), button,
			TRUE, TRUE, 0);
	gtk_signal_connect(GTK_OBJECT(button), "clicked",
			GTK_SIGNAL_FUNC(conf_apply_cb), NULL);
	GTK_WIDGET_SET_FLAGS(button, GTK_CAN_DEFAULT);
	gtk_widget_show(button);

	gtk_widget_show(conf_dialog);
}
